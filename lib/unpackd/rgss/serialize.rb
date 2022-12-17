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

require 'fileutils'
require 'zlib'
require 'pp'
require 'formatador'

require 'unpackd/psych/visitors/yaml_tree'
require 'unpackd/rgss/loader_code.rb'

class Numeric
  def to_digits(num = 3)
    str = to_s
    (num - str.size).times { str = str.prepend("0") }
    return str
  end
end

module RGSS
  def self.change_ext(file, new_ext)
    File.basename(file, '.*') << new_ext
  end

  def self.echo(color="white", line)
    $formatador.display_line("[#{color}]#{line}[/]") if $VERBOSE
  end

  def self.sanitize_filename(filename)
    filename.gsub(/[^0-9A-Za-z]+/, '_')
  end

  def self.files_with_extension(directory, extension)
    Dir.entries(directory).select { |file| File.extname(file) == extension }
  end

  def self.inflate(str)
    Zlib::Inflate.inflate(str).force_encoding('utf-8').delete("\r")
  end

  def self.deflate(str)
    Zlib::Deflate.deflate(str, Zlib::BEST_COMPRESSION)
  end

  def self.dump_data_file(file, data)
    File.open(file, 'wb') { |f| Marshal.dump(data, f)}
  end

  def self.dump_yaml_file(file, data)
    File.open(file, 'wb') { |f| Psych.dump(data, f) }
  end

  def self.dump_raw_file(file, data)
    File.open(file, 'wb') { |f| f.write(data) }
  end

  def self.dump(dumper, file, data)
    send(dumper, file, data)
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
        echo("red", "#{file}: Duplicate ID #{id}")
        formatador.indent do
          formatador.indent do
            elem.pretty_inspect.split(/\n/).each do |line|
              echo("red", "#{line}")
            end
          end
          $formatador.display_line
          echo("red", "Last seen at:\n")
          formatador.indent do
            elem.pretty_inspect.split(/\n/).each do |line|
              echo("red", "#{line}")
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

  def self.load(loader, file)
    send(loader, file)
  rescue
    warn "Exception loading #{file}"
    raise
  end

  def self.title_to_filename(title)
    filename = title.clone
    filename.gsub!(/\\/, "&bs;")
    filename.gsub!(/\//, "&fs;")
    filename.gsub!(/:/, "&cn;")
    filename.gsub!(/\*/, "&as;")
    filename.gsub!(/\?/, "&qm;")
    filename.gsub!(/"/, "&dq;")
    filename.gsub!(/</, "&lt;")
    filename.gsub!(/>/, "&gt;")
    filename.gsub!(/\|/, "&po;")
    return filename
  end

  def self.unpack_scripts(dirs, src, dest, options)
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
      echo("yellow", "Skipping scripts to text")
    else
      echo("green", "Converting scripts to text")
      dump(:dump_yaml_file, dest_file, script_index)
      script_code.each do |file, code|
        dump(:dump_raw_file, file, code)
      end
    end
  end

  def self.pack_scripts(dirs, src, dest, options)
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
      echo("yellow", "Skipping scripts to binary")
    else
      echo("green", "Converting scripts to binary")
      dump(:dump_data_file, dest_file, script_entries, newest_time, options)
    end
  end

  def self.process_file(file, src_file, dest_file, dest_ext, loader, dumper, options)
    fbase = File.basename(file, File.extname(file)).downcase
    formatador = Formatador.new
    src_time = File.mtime(src_file)
    if !options[:force] && File.exist?(dest_file) && (src_time - 1) < File.mtime(dest_file)
      echo("yellow", "Skipping #{file}")
    else
      echo("green", "Converting #{file} to #{dest_ext}")
      data = load(loader, src_file)
      dump(dumper, dest_file, data)
    end
  end

  def self.convert(src, dest, options)
    files = files_with_extension(src[:directory], src[:ext])
    files -= src[:exclude]

    files.each do |file|
      src_file = File.join(src[:directory], file)
      dest_file = File.join(dest[:directory], change_ext(file, 'yaml'))

      process_file(file, src_file, dest_file, dest[:ext], src[:load_file],
                   dest[:dump_file], options)
    end
  end

  def self.extract_scripts(ifile, fname, dirs)
    scripts = load(:load_data_file, ifile)
    if scripts.length < 10
      echo("red", "#{fname}.rxdata Already Extracted!")
      return
    end

    echo("green", "Extracting #{fname}.rxdata")

    # 0=main path, 1=subfolder, 2=sub-subfolder
    level = 0
    # Can only have two layers of folders
    dir_id, file_id, dir_path, dir_name = [1, 1], 1, dirs[:script], nil

    scripts.each_with_index do |e, i|
      _, title, script = e
      title = title_to_filename(title).strip
      script = inflate(script)
      next if title.empty? && script.empty?

      section_name = nil
      if title[/\[\[\s*(.+)\s*\]\]$/]   # Make a folder
        section_name = $~[1].strip
        section_name = "unnamed" if !section_name || section_name.empty?
        folder_num =  (i < scripts.length - 2) ? dir_id[level].to_digits(3) : "999"
        dir_name = folder_num + "_" + section_name

        full_dir_path = File.join(dir_path, dir_name)
        FileUtils.mkdir(full_dir_path) unless File.directory?(full_dir_path)

        dir_id[level] += 1
        if level < dir_id.length-1
          level += 1   # Go one level deeper
          dir_id[level] = 1   # Reset numbering of subfolders
          dir_path = full_dir_path
          dir_name = nil
        end
        file_id = 1   # Reset numbering of script files
      elsif title.start_with?("=====")   # Return to top level directory
        level, dir_path, dir_name = 0, dirs[:script], nil
      end

      # Create .rb script file
      next if script.empty?
      this_folder = dir_path
      this_folder = File.join(this_folder, dir_name) if dir_name
      section_name ||= title.strip
      section_name = "unnamed" if !section_name || section_name.empty?
      file_num =  (i < scripts.length - 1) ? file_id.to_digits(3) : "999"
      ofile = File.join(this_folder, "#{file_num}_#{section_name}.rb")
      dump(:dump_raw_file, ofile, script)
      file_id += 1
    end
  end

  def self.setup_script_loader(ifile)
    binary = deflate(LoaderCode::get_script_loader)
    dump(:dump_data_file, ifile, [[62054200, "Main", binary]])
  end


  def self.extract_yaml(ifile, fname, dirs)
    data = load(:load_data_file, ifile)

    # if data[3].delete("\r").start_with?("# Loader")
    #   echo("red", "#{fname}.rxdata Already Extracting!")
    #   return

    echo("green", "Extracting #{fname}.rxdata")
    ofile = File.join(dirs[:yaml], fname << ".yaml")
    dump(:dump_yaml_file, ofile, data)
  end

  def self.make_backup(files, backup_dir)
    echo("yellow", "Making Backup for #{files.map {|f| File.basename(f, ".*")}}")
    files.each do |file|
      data, fname = load(:load_data_file, file), File.basename(file, ".*")
      if fname.downcase == "scripts" and data.length < 10
        echo("yellow", "#{fname}.rxdata Backup Halted!")
        return
      end
      bfile = File.join(backup_dir, File.basename("#{file}.backup"))
      dump(:dump_data_file, bfile, data)
    end
  end

  def self.revert_backup(files, backup_dir)
    echo("yellow", "Reverting Backup for #{files.map {|f| File.basename(f, ".*")}}")
    files.each do |file|
      bfile = File.join(backup_dir, File.basename("#{file}.backup"))
      dump(:dump_data_file, file, load(:load_data_file, bfile))
    end
  end

  def self.extract(files, dirs)

    make_backup(files, dirs[:backup])
    begin
      files.each do |file|
        fname = File.basename(file, ".*")
        if fname.downcase == "scripts"
          extract_scripts(file, fname,  dirs)
          setup_script_loader(file)
        else
          extract_yaml(file, fname, dirs)
        end
      end
    rescue => e
      revert_backup(files, dirs[:backup])
      echo("red", "#{e}")
    end
  end

  def self.serialize(operation, directory, files, force)
    $formatador = Formatador.new
    self.setup_classes

    base = File.realpath(directory)
    dirs = {
      base:   base,
      data:   get_data_dir(base),
      yaml:   get_yaml_dir(base),
      script: get_script_dir(base),
      backup: get_backup_dir(base)
    }

    dirs.each_value { |d| FileUtils.mkdir(d) unless File.directory?(d) }

    yaml_scripts = SCRIPTS_BASE + YAML_EXT
    yaml = {
      directory: dirs[:yaml],
      exclude:   [yaml_scripts],
      ext:       YAML_EXT,
      load_file: :load_yaml_file,
      dump_file: :dump_yaml_file,
    }

    scripts = SCRIPTS_BASE + XP_DATA_EXT
    data = {
      directory: dirs[:data],
      exclude:   [scripts],
      ext:       XP_DATA_EXT,
      load_file: :load_data_file,
      dump_file: :dump_data_file,
    }

    case operation
    when :d
      puts "d"
    when :extract
      extract(files, dirs)
      # convert(data, yaml, {})
      # unpack_scripts(dirs, scripts, yaml_scripts, options)
    when :combine
      convert(yaml, data, {})
      pack_scripts(dirs, yaml_scripts, scripts, options)
    else
      fail "Unrecognized Operation :#{operation}"
    end
  end
end
