# coding: utf-8
lib = File.join(File.expand_path('..', __FILE__), 'lib')
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

  spec.files         = [
    "spec/spec_helper.rb", "bin/unpackd", "lib/unpackd/version.rb",
    "lib/unpackd/basic_coder.rb", "lib/unpackd/psych.rb",
    "lib/unpackd/rgss.rb", "lib/unpackd/rgss/loader_code.rb",
    "lib/unpackd/rgss/serialize.rb", "lib/unpackd/rpg.rb", "lib/unpackd/utils.rb",
    "lib/unpackd/utils/collections.rb", "unpackd.gemspec", "Gemfile"
  ]
  spec.executables   = 'unpackd'
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'ocra'

  spec.add_dependency "optimist"
  spec.add_dependency "scanf"
  spec.add_dependency "psych", "2.0.0"
  spec.add_dependency "formatador"
  spec.add_dependency "zlib"
  spec.add_dependency "fileutils"
end
