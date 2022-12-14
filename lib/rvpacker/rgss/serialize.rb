# Copyright (c) 2013 Howard Jeng
# Copyright (c) 2014-2015 Andrew Kesterson, Rachel Wall
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'rvpacker/psych/visitors/yaml_tree'
require 'fileutils'
require 'zlib'
require 'pp'
require 'formatador'

module RGSS
  def self.change_extension(file, new_ext)
    File.basename(file, '.*') << new_ext
  end

  def self.sanitize_filename(filename)
    filename.gsub(/[^0-9A-Za-z]+/, '_')
  end

  def self.files_with_extension(directory, extension)
    Dir.entries(directory).select { |file| File.extname(file) == extension }
  end

  def self.inflate(str)
    Zlib::Inflate.inflate(str).force_encoding('utf-8')
  end

  def self.deflate(str)
    Zlib::Deflate.deflate(str, Zlib::BEST_COMPRESSION)
  end

  def self.dump_data_file(file, data, time, options)
    File.open(file, 'wb') { |f| Marshal.dump(data, f) }
    File.utime(time, time, file)
  end

  def self.dump_yaml_file(file, data, time, options)
    File.open(file, 'wb') { |f| Psych.dump(data, f, options) }
    File.utime(time, time, file)
  end

  def self.dump_save(file, data, time, options)
    File.open(file, 'wb') { |f| data.each { |chunk| Marshal.dump(chunk, f) } }
    File.utime(time, time, file)
  end

  def self.dump_raw_file(file, data, time, options)
    File.open(file, 'wb') { |f| f.write(data) }
    File.utime(time, time, file)
  end

  def self.dump(dumper, file, data, time, options)
    send(dumper, file, data, time, options)
  rescue
    warn "Exception dumping #{file}"
    raise
  end

  def self.load_data_file(file)
    File.open(file, 'rb') { |f| Marshal.load(f) }
  end

  def self.load_yaml_file(file)
    formatador = Formatador.new
    obj = nil
    File.open(file, 'rb') { |f| obj = Psych.load(f) }
    max = 0
    return obj unless obj.is_a?(Array)
    seen = {}
    obj.each do |elem|
      next if elem.nil?
      if elem.instance_variable_defined?(:@id)
        id = elem.instance_variable_get(:@id)
      else
        id = nil
        elem.instance_variable_set(:@id, nil)
      end
      next if id.nil?

      if seen.key?(id)
        formatador.display_line("[red]#{file}: Duplicate ID #{id}[/]")
        formatador.indent do
          formatador.indent do
            elem.pretty_inspect.split(/\n/).each do |line|
              formatador.display_line("[red]#{line}[/]")
            end
          end
          formatador.display_line
          formatador.display_line("[red]Last seen at:\n[/]")
          formatador.indent do
            elem.pretty_inspect.split(/\n/).each do |line|
              formatador.display_line("[red]#{line}[/]")
            end
          end
        end
        exit 1
      end
      seen[id] = elem
      max = ((id + 1) unless id < max)
    end
    obj.each do |elem|
      next if elem.nil?
      id = elem.instance_variable_get(:@id)
      if id.nil?
        elem.instance_variable_set(:@id, max)
        max += 1
      end
    end
    obj
  end

  def self.load_raw_file(file)
    File.binread(file)
  end

  def self.load_save(file)
    File.open(file, 'rb') do |f|
      data = []
      data << Marshal.load(f) until f.eof?
      data
    end
  end

  def self.load(loader, file)
    send(loader, file)
  rescue
    warn "Exception loading #{file}"
    raise
  end

  def self.scripts_to_text(dirs, src, dest, options)
    formatador = Formatador.new
    src_file = File.join(dirs[:data], src)
    dest_file = File.join(dirs[:yaml], dest)
    fail "Missing #{src}" unless File.exist?(src_file)

    script_entries = load(:load_data_file, src_file)
    check_time = !options[:force] && File.exist?(dest_file)
    oldest_time = File.mtime(dest_file) if check_time

    file_map     = Hash.new(-1)
    script_index = []
    script_code  = {}

    idx = 0
    script_entries.each do |script|
      magic_number = idx += 1
      script_name  = script[1]
      code         = inflate(script[2])

      script_name.force_encoding('utf-8')

      if code.length > 0
        filename = script_name.empty? ? 'blank' : sanitize_filename(script_name)
        key      = filename.upcase
        value    = (file_map[key] += 1)
        actual_filename = filename + (value == 0 ? "" : ".#{value}") + RUBY_EXT
        script_index << [magic_number, script_name, actual_filename]

        full_filename = File.join(dirs[:script], actual_filename)
        script_code[full_filename] = code
        check_time = false unless File.exist?(full_filename)
        oldest_time = [File.mtime(full_filename), oldest_time].min if check_time
      else
        script_index << [magic_number, script_name, nil]
      end
    end

    src_time = File.mtime(src_file)
    if check_time && (src_time - 1) < oldest_time
      formatador.display_line('[yellow]Skipping scripts to text[/]') if $VERBOSE
    else
      formatador.display_line('[green]Converting scripts to text[/]') if $VERBOSE
      dump(:dump_yaml_file, dest_file, script_index, src_time, options)
      script_code.each do |file, code|
        dump(:dump_raw_file, file, code, src_time, options)
      end
    end
  end

  def self.scripts_to_binary(dirs, src, dest, options)
    formatador = Formatador.new
    src_file   = File.join(dirs[:yaml], src)
    dest_file  = File.join(dirs[:data], dest)
    fail "Missing #{src}" unless File.exist?(src_file)
    check_time  = !options[:force] && File.exist?(dest_file)
    newest_time = File.mtime(src_file) if check_time

    index = load(:load_yaml_file, src_file)
    script_entries = []
    index.each do |entry|
      magic_number, script_name, filename = entry
      code = ''
      if filename
        full_filename = File.join(dirs[:script], filename)
        fail "Missing script file #{filename}" unless File.exist?(full_filename)
        newest_time = [File.mtime(full_filename), newest_time].max if check_time
        code = load(:load_raw_file, full_filename)
      end
      script_entries << [magic_number, script_name, deflate(code)]
    end
    if check_time && (newest_time - 1) < File.mtime(dest_file)
      formatador.display_line('[yellow]Skipping scripts to binary[/]') if $VERBOSE
    else
      formatador.display_line('[green]Converting scripts to binary[/]') if $VERBOSE
      dump(:dump_data_file, dest_file, script_entries, newest_time, options)
    end
  end

  def self.process_file(file, src_file, dest_file, dest_ext, loader, dumper, options)
    fbase = File.basename(file, File.extname(file)).downcase
    formatador = Formatador.new
    src_time = File.mtime(src_file)
    if !options[:force] && File.exist?(dest_file) && (src_time - 1) < File.mtime(dest_file)
      formatador.display_line("[yellow]Skipping #{file}[/]") if $VERBOSE
    else
      formatador.display_line("[green]Converting #{file} to #{dest_ext}[/]") if $VERBOSE
      data = load(loader, src_file)
      dump(dumper, dest_file, data, src_time, options)
    end
  end

  def self.convert(src, dest, options)
    files = files_with_extension(src[:directory], src[:ext])
    files -= src[:exclude]

    files.each do |file|
      src_file = File.join(src[:directory], file)
      dest_file = File.join(dest[:directory], change_extension(file, dest[:ext]))

      process_file(file, src_file, dest_file, dest[:ext], src[:load_file],
                   dest[:dump_file], options)
    end
  end

  def self.convert_saves(base, src, dest, options)
    save_files = files_with_extension(base, src[:ext])
    save_files.each do |file|
      src_file = File.join(base, file)
      dest_file = File.join(base, change_extension(file, dest[:ext]))

      process_file(file, src_file, dest_file, dest[:ext], src[:load_save],
                   dest[:dump_save], options)
    end
  end

  def self.serialize(version, direction, directory, options = {})
    fail "#{directory} not found" unless File.directory?(directory)

    setup_classes(version, options)
    options = options.dup
    options[:sort] = true if [:vx, :xp].include?(version)
    options[:flow_classes] = FLOW_CLASSES
    options[:line_width] ||= 130

    table_width = options[:table_width]
    RGSS.reset_const(Table, :MAX_ROW_LENGTH, table_width ? table_width : 20)

    base = File.realpath(directory)

    dirs = {
      base:   base,
      data:   get_data_directory(base),
      yaml:   get_yaml_directory(base),
      script: get_script_directory(base)
    }

    dirs.each_value { |d| FileUtils.mkdir(d) unless File.directory?(d) }

    exts = {
      ace: ACE_DATA_EXT,
      vx:  VX_DATA_EXT,
      xp:  XP_DATA_EXT
    }

    yaml_scripts = SCRIPTS_BASE + YAML_EXT
    yaml = {
      directory: dirs[:yaml],
      exclude:   [yaml_scripts],
      ext:       YAML_EXT,
      load_file: :load_yaml_file,
      dump_file: :dump_yaml_file,
      load_save: :load_yaml_file,
      dump_save: :dump_yaml_file
    }

    scripts = SCRIPTS_BASE + exts[version]
    data = {
      directory: dirs[:data],
      exclude:   [scripts],
      ext:       exts[version],
      load_file: :load_data_file,
      dump_file: :dump_data_file,
      load_save: :load_save,
      dump_save: :dump_save
    }

    case direction
    when :data_bin_to_text
      convert(data, yaml, options)
      scripts_to_text(dirs, scripts, yaml_scripts, options)
    when :data_text_to_bin
      convert(yaml, data, options)
      scripts_to_binary(dirs, yaml_scripts, scripts, options)
    when :save_bin_to_text
      convert_saves(base, data, yaml, options)
    when :save_text_to_bin
      convert_saves(base, yaml, data, options)
    when :scripts_bin_to_text
      scripts_to_text(dirs, scripts, yaml_scripts, options)
    when :scripts_text_to_bin
      scripts_to_binary(dirs, yaml_scripts, scripts, options)
    when :all_bin_to_text
      convert(data, yaml, options)
      scripts_to_text(dirs, scripts, yaml_scripts, options)
      convert_saves(base, data, yaml, options)
    when :all_text_to_bin
      convert(yaml, data, options)
      scripts_to_binary(dirs, yaml_scripts, scripts, options)
      convert_saves(base, yaml, data, options)
    else
      fail "Unrecognized direction :#{direction}"
    end
  end
end
