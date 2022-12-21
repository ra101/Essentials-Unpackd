

<div align="center">
    <h1> Essentials Unpack'd </h1>
    <p><i><code>unpackd</code> is tool for a Pokémon Essentials, to <b>extract</b> data binaries (<code>.rxdata</code>) to readable <code>.rb</code> and <code>.yaml</code> files and to <b>combine</b> it back, Thus making your game to be version-controlled and to be collaborated on.</i></p><br/>
    <img src="https://img.shields.io/badge/Made%20with-Ruby-DE3F24?style=for-the-badge&logo=ruby" alt="Made with Ruby"> <a href="https://essentialsdocs.fandom.com/"><img src="https://img.shields.io/badge/Essentials-v20.1-ffcb05?style=for-the-badge&labelColor=3c5aa6&logo=pokemon" alt="Essentials v20.1"></a> <a href="https://github.com/ra101/Essentials-Unpackd/releases/latest/download/unpackd.exe"><img src="https://img.shields.io/badge/Download-v3.0.0-grey?style=for-the-badge&logo=windows&labelColor=639" alt="download"></a> <a href="https://www.buymeacoffee.com/ra101"><img src="https://img.shields.io/badge/sponser-💝-ffdd99?style=for-the-badge&logo=buymeacoffee&logoColor=white&labelColor=dd6633" alt="download"></a>
</div><br/>

<br/>

## Usage

```bash
$ unpackd.exe --help
Essentials Unpack\'d v3.0.0

`unpackd` is a tool \for a Pokémon Essentials, to extract data binaries (.rxdata)
  to readable .rb and .yaml files and to combine it back, thus making
  your game to be version-controlled and to be collaborated on.

Usage:
        unpackd {--extract|--combine|-b|-r} [options]

Options:
  -e, --extract        Extract given binaries(.rxdata) into individual .yaml/.rb
  -c, --combine        Combine given .yaml/.rb files into binaries(.rxdata)
  -b, --backup         Make Backup \for given binary(.rxdata) files
  -r, --revert         Revert given binary(.rxdata) from Backup Folder
  
  -d, --project=<s>    Essentials project path. (default: Current Folder)
  -f, --files=<s+>     File Names \for .rxdata/.yaml/.rb to operate on. (default: *)
  
  -F, --force          Used with `--combine` to Pack Data Forcefully
  -s, --silent         Do not output any information \while processing
  
  -v, --version        Print version and \exit
  -h, --help           Show this message
```

<br/>

### Examples

<br/>

- To **Extract** `Scripts.rxdata` and `Tilesets.rxdata` of a game in *"D:\\Examples\\MyEssentialsGame"*:

> ```bash
>$ unpackd.exe --extract --project "D:\Examples\MyEssentialsGame" --files scripts tilesets
> ```
> 
> This will create 3 Folders, `Backup`, `Scripts` and `YAML` in *"D:\\Examples\\MyEssentialsGame**\\Data**"* folder.
>
> - Firstly, Backup files will be created in `Data\Backup` (`*.rxdata.backup` files)
>- `Scripts.rxdata`  consists of many ruby scripts and these now will be extracted to individual `.rb` files placed in grouped folders within  `Data\Scripts` folder.
>  - `Scripts.rxdata` will be replaced with a loader file, this file can read the individual `.rb` files in `Data\Scripts` Folder, Therefore making Game.exe still playable! *This would not work, if game is encrypted !*
>- `Tilesets.rxdata` will be extracted to a readable `Tilesets.yaml` file within  `Data\YAML` folder.
> - If at any point, the scripts is unable to perform extraction, mentioned Backup files will be reinstated.


<br/>
<br/>

- To **Combine** { ruby scripts in `Data/Scripts`  to `Scripts.rxdata `} and { `Tilesets.yaml` to `Tilesets.rxdata` }:

> ```bash
> $ unpackd.exe --combine --project "D:\Examples\MyEssentialsGame" --files scripts tilesets
> ```
>
> This will create 3 Folders, `Backup`, `Scripts` and `YAML` in *"D:\\Examples\\MyEssentialsGame**\\Data**"* folder.
>
> - Firstly, Backup files will be created in `Data\Backup` (`*.rxdata.backup` files)
> - Will check if the `Scripts.rxdata` is a loader file or a already data packed file.
>   - If in case, it is already a packed data file, this operation will skipped, unless `--force` flag is passed along.
>   - Else, ruby scripts will be reintegrated back into `Scripts.rxdata`
> - `Tilesets.yaml` will be converted back to `Tilesets.rxdata`.
> - If at any point, the scripts is unable to perform combination, mentioned Backup files will be reinstated.


<br/>
<br/>

- To create a general **Backup** for `Scripts.rxdata` and `Tilesets.rxdata`:

> ```bash
> $ unpackd.exe --backup --project "D:\Examples\MyEssentialsGame" --files scripts tilesets
> ```
>


<br/>
<br/>

- To **Revert** a already created backup of `Scripts.rxdata` and `Tilesets.rxdata`:

> ```bash
> $ unpackd.exe --revert --project "D:\Examples\MyEssentialsGame" --files scripts tilesets
> ```

<br/>

### Tips and Tricks

- Put `unpackd.exe` in game directory, it a light file and it removes the need to pass `--project` flag

- Currently only `Tilesets` and `Scripts` are understandable, I am not sure about rest of files.

- To add `YAML` in your version control add `!Data/YAML/` to `.gitignore`.

  - ```bash
    $ echo !Data/YAML/ >> .gitignore
    ```

- Extracted `Scripts.rxdata` cannot be loaded into RPG Maker, even with loader file, always combine it, if you plan on using scripteditor of RPG Maker.

- Using `---files` flag again and again for same files, can be a bit effortful, create a batch file or makefile for you wokrflow, I have add a [makefile.template](https://raw.githubusercontent.com/ra101/Essentials-Unpackd/core/makefile.template) in the repo, as a base to add on.

- In Case, you if don't use a VCS (big mistake), be aware of backups! Suppose you made changes to a file, combined it to run the game and it did not work (right now file is bad but backup is good). but if you make another change and combined forcefully, even if the file is good, backup becomes bad!

<br/>

## Credits

**Essentials Unpack'd** is quite different from original files and libs, but Authors must be credited for the grand majority of the work that `unpackd` does, without them this wound have not been possible.

- **Howard "SiCrane" Jeng** for original [YAML importer/exporter](https://www.gamedev.net/forums/topic/646333-rpg-maker-vx-ace-data-conversion-utility/); serialization, data conversion.
- **Aaron Patterson** for `psych 2.0.0` bug fixes.
- **Andrew Kesterson** for converting a simple forum post to working version controlled ruby gem!
- **Rachel Wall** for code optimizing and maintaining since 2014.
- **Maruno** for all process regarding `Scripts.rxdata`, extract, combine and loader.

<br/>

## Dev-Installation

```bash
$ git clone https://github.com/ra101/Essentials-Unpackd.git
$ cd Essentials-Unpackd
$ gem install bundler
$ bundle install
```

<br/>

## Dev-Usage

```bash
$ bundle exec unpackd {--extract|--combine|-b|-r} [options]
```

<br/>


## Workflow

### General

`unpackd` consists of following parts:

* `rgss.rb` : Stub classes for serialization of RPG Maker game data
* `serialize.rb` : core mechanice behind data processing
* `psych.rb`: Overriding Psych lib to make output more readable
* `unpackd`: The script you call on the frontend.



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

```

```
