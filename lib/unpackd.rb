# Automatically require all `unpackd` Ruby files in 'lib'.
require "unpackd/version.rb"
require "unpackd/psych.rb"
require "unpackd/rgss.rb"
require "unpackd/rgss/loader_code.rb"
require "unpackd/rgss/serialize.rb"
require "unpackd/utils.rb"

# `unpackd` is a tool for Pokémon Essentials, to extract data binaries (.rxdata)
#   to readable .rb and .yaml files and to combine them back, thus making
#   your game to be version-controlled and to be collaborated on.
module Unpackd
end
