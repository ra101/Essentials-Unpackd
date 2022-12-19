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

require 'unpackd/psych'
require 'unpackd/rgss/loader_code'

class Numeric
  def to_digits(num = 3)
    str = to_s
    (num - str.size).times { str = str.prepend("0") }
    return str
  end
end

module RGSS

  SCRIPTS_FNAME = "Scripts"
  RX_EXT = ".rxdata"
  RB_EXT = ".rb"
  YML_EXT = ".yaml"
  BK_EXT = ".backup"

  def self.change_ext(file, new_ext)
    File.basename(file, '.*') << new_ext
  end

  def self.echo(color="white", line)
    $formatador.display_line("[#{color}]#{line}[/]") unless $SILENT
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

  def self.filename_to_title(filename)
    filename = filename.bytes.pack('U*')
    title = ""
    if filename[/^[^_]*_(.+)$/]
      title = $~[1]
      title = title[0..-4] if title.end_with?(".rb")
      title = title.strip
    end
    title = "unnamed" if !title || title.empty?
    title.gsub!(/&bs;/, "\\")
    title.gsub!(/&fs;/, "/")
    title.gsub!(/&cn;/, ":")
    title.gsub!(/&as;/, "*")
    title.gsub!(/&qm;/, "?")
    title.gsub!(/&dq;/, "\"")
    title.gsub!(/&lt;/, "<")
    title.gsub!(/&gt;/, ">")
    title.gsub!(/&po;/, "|")
    return title
  end

  def self.aggregate_from_folder(path, scripts, level = 0)
    # A DFS to get all Scripts!

    # Add all files and folder of current level
    files, folders = [], []
    Dir.foreach(path) do |f|
      next if f == '.' || f == '..'
      is_dir = File.directory?(File.join(path, f))
      if is_dir then folders.push(f) else files.push(f) end
    end

    # Aggregate individual script files into Scripts.rxdata
    files.sort!
    files.each do |f|
      section_name = filename_to_title(f)
      content = File.open(File.join(path, f), "rb") { |f2| f2.read }#.gsub(/\n/, "\r\n")
      scripts << [rand(999_999), section_name, deflate(content)]
    end

    # Check each subfolder for scripts to aggregate
    folders.sort!
    folders.each do |f|
      section_name = filename_to_title(f)
      scripts << [rand(999_999), "==================", deflate("")] if level == 0
      scripts << [rand(999_999), "", deflate("")] if level == 1
      scripts << [rand(999_999), "[[ " + section_name + " ]]", deflate("")]
      aggregate_from_folder(File.join(path, f), scripts, level + 1)
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

  def self.extract_scripts(ifile, fname, dirs)
    scripts = load(:load_data_file, ifile)
    if scripts.length < 10
      echo("red", "#{fname}#{RX_EXT} Already Extracted!")
      return
    end

    echo("green", "Extracting #{fname}#{RX_EXT}")

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
      ofile = File.join(this_folder, "#{file_num}_#{section_name}#{RB_EXT}")
      dump(:dump_raw_file, ofile, script)
      file_id += 1
    end

    setup_script_loader(ifile)
  end

  def self.combine_scripts(ifile, fname, dirs, force)
    scripts_data = load(:load_data_file, ifile)
    info_str = "#{fname}#{RX_EXT} Already Combined! "
    if scripts_data.length > 10
      if force
        echo("yellow", info_str)
      else
        echo("red", "#{info_str}Use `--force` to Pack Data Forcefully.")
        return
      end
    end

    scripts_data = []
    aggregate_from_folder(dirs[:script], scripts_data)
    echo("green", "Combining #{fname}#{RX_EXT}")
    dump(:dump_data_file, ifile, scripts_data)
  end

  def self.setup_script_loader(ifile)
    echo("blue", "Creating Loader for #{File.basename(ifile)}")
    binary = deflate(LoaderCode::get_script_loader)
    dump(:dump_data_file, ifile, [[62054200, "Main", binary]])
  end

  def self.setup_yaml_loader(fname, ifile)
    echo("blue", "Creating Loader for #{File.basename(ifile)}")
    binary = deflate(LoaderCode::get_yaml_loader(fname))
    dump(:dump_data_file, ifile, binary)
  end


  def self.extract_yaml(ifile, fname, dirs)
    data = load(:load_data_file, ifile)

    # Loader Check for YAML
    # begin
    #   infated_code = inflate(data)
    # rescue TypeError => e
    #   nil
    # else
    #   if infated_code.class == String
    #     if infated_code.downcase.start_with?("# loader")
    #       puts infated_code
    #       echo("red", "#{fname}#{RX_EXT} Already Extracted!")
    #       return
    #     end
    #   end
    # end

    echo("green", "Extracting #{fname}#{RX_EXT}")
    ofile = File.join(dirs[:yaml], fname + YML_EXT)
    dump(:dump_yaml_file, ofile, data)

    # setup_yaml_loader(fname, ifile)
  end

  def self.combine_yaml(ifile, fname, dirs)
    data = load(:load_yaml_file, ifile)
    echo("green", "Combining #{fname}#{YML_EXT}")
    ofile = File.join(dirs[:data], fname + "#{RX_EXT}")
    dump(:dump_data_file, ofile, data)
  end

  def self.make_backup(files, backup_dir)
    echo("yellow", "Making Backup for #{files.map {|f| File.basename(f, ".*")}}")
    files.each do |file|
      data, fname = load(:load_data_file, file), File.basename(file, ".*")
      if fname.downcase == SCRIPTS_FNAME.downcase and data.length < 10
        next echo("yellow", "#{SCRIPTS_FNAME}#{RX_EXT} is Loader, Backup Canceled!")
      end
      bext = if file.end_with?(BK_EXT) then "" else BK_EXT end
      bfile = File.join(backup_dir, File.basename("#{file}#{bext}"))
      dump(:dump_data_file, bfile, data)
    end
  end

  def self.revert_backup(files, backup_dir)
    echo("yellow", "Reverting Backup for #{files.map {|f| File.basename(f, ".*")}}")
    files.each do |file|
      bext = if file.end_with?(BK_EXT) then "" else BK_EXT end
      bfile = File.join(backup_dir, File.basename("#{file}#{bext}"))
      dump(:dump_data_file, file, load(:load_data_file, bfile))
    end
  end

  def self.extract(files, dirs)
    make_backup(files, dirs[:backup])
    begin
      files.each do |file|
        fname = File.basename(file, ".*")
        if fname.downcase == SCRIPTS_FNAME.downcase
          extract_scripts(file, fname,  dirs)
        else
          extract_yaml(file, fname, dirs)
        end
      end
    rescue => e
      revert_backup(files, dirs[:backup])
      echo("red", "#{e}")
    end
  end

  def self.decode_yaml(yfile, dirs)
    index = load(:load_yaml_file, yfile)
    str = Marshal.dump(index).gsub("\000", "null_byte_here")
    exec("echo #{str}")
  end

  def self.combine(files, dirs, force)
    rxfiles = [] # To be Used by Backup Functions
    files.each do |file|
      rxfiles += Dir[
        File.join(dirs[:data], File.basename(file, ".*") + "#{RX_EXT}")
    ]
    end

    make_backup(rxfiles, dirs[:backup])
    begin
      files.each do |file|
        fname = File.basename(file, ".*")
        if fname.downcase == SCRIPTS_FNAME.downcase
          combine_scripts(file, fname,  dirs, force)
        else
          combine_yaml(file, fname, dirs)
        end
      end
    rescue => e
      revert_backup(rxfiles, dirs[:backup])
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

    case operation
    when :extract
      extract(files, dirs)
    when :combine
      combine(files, dirs, force)
    when :revert
      revert_backup(files, dirs[:backup])
    when :backup
      make_backup(files, dirs[:backup])
    # when :yml2rb
    #   puts decode_yaml(files[0], dirs)
    else
      fail "Unrecognized Operation :#{operation}"
    end
  end
end
