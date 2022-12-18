# Automatically require all `unpackd` Ruby files in 'lib'.
require "unpackd/version.rb"
require "unpackd/basic_coder.rb"
require "unpackd/psych.rb"
require "unpackd/rgss.rb"
require "unpackd/rgss/loader_code.rb"
require "unpackd/rgss/serialize.rb"
require "unpackd/rpg.rb"
require "unpackd/utils.rb"
require "unpackd/utils/collections.rb"

# `unpackd` packs and unpacks binary RPG Maker project data to and from YAML
# so that it can be version-controlled and collaborated on.
module Unpackd
end
