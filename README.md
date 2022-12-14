# Essentials Unpack'd
_A tool to pack and unpack binary RPG Maker project data to and from YAML so it can be version-controlled and collaborated on._

`unpackd` consists of 3 parts:

* RPG library (stub classes for serialization of RPG Maker game data)
* RGSS library (some more classes for RPG Maker serialization)
* `unpackd` (the script you call on the frontend)

## Credit to SiCrane
The RPG and RGSS libraries were originally taken from [SiCrane's YAML importer/exporter](http://www.gamedev.net/topic/646333-rpg-maker-vx-ace-data-conversion-utility/) on the [gamedev.net forums](http://www.gamedev.net/index). Though `unpackd` is starting to drift from the original libraries, SiCrane still gets original credit for the grand majority of the work that `unpackd` does.

## Installation


```sh
$ git clone https://github.com/Solistra/unpackd.git
$ cd unpackd
$ gem install bundler
$ bundle install
```

## Usage

```
$ bundle exec unpackd --help
unpackd packs and unpacks binary RPG Maker project data to and from YAML so
that it can be version-controlled and collaborated on.

Usage:
        bundle exec unpackd {--pack|--unpack} [options]

Options:
  -a, --action=<s>          Action to perform on the project (pack|unpack)
  -p, --pack                Pack YAML into binary RPG Maker data
  -u, --unpack              Unpack binary RPG Maker data to YAML
  -d, --project=<s>         RPG Maker project directory
  -t, --project-type=<s>    Project type (xp|vx|ace)
  -D, --database=<s>        Only work on the given database
  -f, --force               Update target even when source is older than target
  -V, --verbose             Print verbose information while processing
  -v, --version             Print version and exit
  -h, --help                Show this message
```

For example, to unpack an RPG Maker VX Ace project in ~/Documents/RPGVXAce/Project1:

```
 bundle exec unpackd --unpack --project ~/Documents/RPGVXAce/Project1 --project-type ace
```

...this will expand all of the project's binary Data/ files into (PROJECT)/YAML/ as YAML files; scripts will be unpacked as individual .rb files into (PROJECT)/Scripts/.

To take a previously unpacked project and pack it back up:

```
bundle exec unpackd --pack --project ~/Documents/RPGVXAce/Project1 --project-type ace
```

...this will take all of the YAML files in (PROJECT)/YAML (and all of the scripts in (PROJECT)/Scripts) and repack all of your (PROJECT)/Data/ files. You can trust this to completely reassemble your Data/ directory as long as both the Scripts/ and YAML/ directories remain intact.

## Workflow

### General

This is great for teams that are collaborating on an RPG Maker project. Just add a few steps to your existing workflow:

* Checkout the project from version control
* Run `unpackd --pack` on the project to re-pack it for the RPG Maker editor
* Load up RPG Maker and do whatever you're going to do
* Save the project
* Run `unpackd --unpack` on the project
* Commit everything to version control

...now your project can be forked/merged in a much more safe/sane way, and you don't have to have someone bottlenecking the entire process.

**Note:** You can now safely ignore the 'Data/' directory using the ignore file for the version control software you are using (.gitignore, .hgignore, .cvsignore -- whichever applies) as the 'Data/' directory is no longer required to rebuild the project locally.

### Avoiding Map Collisions

One thing that `unpackd` really can't help you with right now (and, ironically, probably one of the reasons you want it) is map collisions. Consider this situation:

* The project has 10 maps in it, total.
* Developer A makes a new map; it gets saved by the editor as 'Map011'.
* Developer B makes a new map, in a different branch; it also gets saved by the editor as 'Map011'.
* Developer A and Developer B attempt to merge their changes -- the merge fails because of the collision on the 'Map011' file.

The best way to avoid this is to use blocks of pre-allocated maps. You appoint one person in your project to be principally responsible for the map assets; it then becomes this person's responsibility to allocate maps in "blocks" so that people can work on maps in a distributed way without clobbering one another. The workflow looks like this:

* The project has 10 maps in it, total.
* Developer A needs to make 4 maps. He sends a request to the "map owner", requesting a block of 4 maps.
* The map owner creates 4 default, blank maps, and names them all "Request #12345" for Developer A
* Developer A starts working on his maps
* Developer B needs to make 6 maps. He sends a request to the "map owner", requesting a block of 6 maps.
* The map owner creates 6 default, blank maps, and names them all "Request #12346" for Developer B
* Developer B starts working on his maps

Using this workflow, it doesn't matter what order Developers A and B request their map blocks in _or_ what order the map owner creates their map blocks in. By giving the map owner the authority to create the map blocks, individual developers can work freely in their map blocks: they can rename them, reorder them, change all of the map attributes (size, tileset, and so on), without getting in danger of a map collision.

While this may seem like an unnecessary process, it is a reasonable workaround. For a better explanation of why `unpackd` can't do this for you, read the next section.

## Automatic ID generation

You can add new elements to the YAML files manually, and leave their `id:` field set to `null`. This will cause the `unpackd` pack action to automatically assign them a new ID number at the end of the sequence (e.g., if you have 17 items, the new one becomes ID 18). This is mainly handy for adding new scripts to the project without having to open the RPG Maker editor and paste the script in; just make the new script file, add its entry in YAML/Scripts.yaml, and the designer will have your script accessible the next time they repack and open the project.

Also, the `unpackd` tool sets the ID of script files to an autoincrementing integer. The scripts exist in the database with a magic number that I can't recreate, and nothing in the editor (RPG VX Ace anyway) seems to care if the magic number changes. It doesn't even affect the ordering. So in order to support adding new scripts with null IDs, like everything else, the magic numbers on scripts are disregarded and a new ID number is forced on the scripts when the `unpackd` `pack` action occurs.

Note that this does not apply to map files; **do not** try changing the map ID numbers manually (see the "Avoiding Map Collisions" workflow, above, and "Why unpackd can't help with map collisions", below).

## Why `unpackd` can't help with map collisions

If you look at the map collision problem described above, the way out of this situation might seem obvious: "Rename Map011.yaml in one of the branches to Map012.yaml, and problem solved." However, there are several significant problems with this approach:

* The ID numbers on the map files correspond to ID number entries in MapInfos.yaml (and the corresponding MapInfos binary files)
* The ID numbers are used to specify a parent/child relationship between one or more maps
* The ID numbers are used to specify the target of a map transition/warp event in event scripting

This means that changing the ID number assigned to a map (and, thereby, making it possible to merge 2 maps with the same ID number) becomes _very_ nontrivial. The event scripting portion, especially, presents a difficult problem for `unpackd` to overcome. It is simple enough for `unpackd` to change the IDs of any new map created, and to change the reference to that ID number from any child maps; however, the events are where it gets sticky. The format of event calls in RPG Maker map files is not terribly well defined, and even if it was, I sincerely doubt that you want `unpackd` tearing around in the guts of your map events.


## Psych 2.0.0 Dependency

From SiCrane:

> I used cygwin's ruby 1.9.3 and the Psych 2.0.0 ruby gem, which appears to be the most recent version. However, Psych 2.0.0 has some bugs that impacted the generated YAML (one major and one minor) which I monkey patched, and since I was already rewriting the Psych code, I added some functionality to make the generated YAML prettier. Long story short, this code probably won't work with any version of Psych but 2.0.0.
