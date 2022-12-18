#!/usr/bin/env ruby

exec(
    "ocra --console --gem-full=./unpackd.gemspec --output ./dist/unpackd.exe "\
    "--add-all-core --gemfile Gemfile ./bin/unpackd "\
    "--dll ruby_builtin_dlls/libgmp-10.dll --dll ruby_builtin_dlls/zlib1.dll"
)
