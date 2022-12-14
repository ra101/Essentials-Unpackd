# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'unpackd/version'

Gem::Specification.new do |spec|
  spec.name          = 'unpackd'
  spec.version       = Unpackd::VERSION
  spec.authors       = ["ra101", "Howard Jeng", "Andrew Kesterson", 'Solistra']
  spec.email         = ['ping@ra101.dev']
  spec.summary       = %q{Pack and unpack Pokemon Essentials Data files}
  spec.description   = %(
    A tool to pack and unpack binary Pokemon Essentials Data to and from YAML so
    it can be version-controlled and collaborated on.
  ).gsub(/\s+/, ' ').strip
  spec.homepage      = "https://github.com/ra101/unpackd"
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.executables   = spec.files.grep(%r{^bin/}) { 'unpackd' }
  spec.require_paths = ['lib']

  spec.add_dependency "optimist"
  spec.add_dependency "scanf"
  spec.add_dependency "psych", "2.0.0"
  spec.add_dependency "formatador"
end
