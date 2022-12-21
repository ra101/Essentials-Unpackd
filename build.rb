#!/usr/bin/env ruby
require 'fileutils'

dist_path = File.join(Dir.pwd, 'dist')
FileUtils.mkdir(dist_path) unless File.directory?(dist_path)

exec(
    "ocra --console --gem-full=./unpackd.gemspec --output ./dist/unpackd.exe "\
    "--gemfile ORCA_Gemfile ./bin/unpackd #{ARGV.join(' ')} "\
    "--dll ruby_builtin_dlls/libgmp-10.dll --dll ruby_builtin_dlls/zlib1.dll"
)
