# Automatically require all `unpackd` Ruby files in 'lib'.
Dir[File.expand_path('../**/*.rb', __FILE__)].each(&method(:require))

# `unpackd` packs and unpacks binary RPG Maker project data to and from YAML
# so that it can be version-controlled and collaborated on.
module Unpackd
end
