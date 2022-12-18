module LoaderCode

    def self.traceback_report
        traceback_report = "# This does not work if the game is encrypted!\n\n" \
            "def traceback_report\n" \
            "  backtrace = $!.backtrace.clone\n" \
            "  backtrace.each{ |bt|\n" \
            "    bt.sub!(/\\{(\\d+)\\}/) {\"[\#{$1}]\#{$RGSS_SCRIPTS[$1.to_i][1]}\"}\n" \
            "  }\n" \
            "  return $!.message + \"\\n" \
            "\\n" \
            "\" + backtrace.join(\"\\n" \
            "\")\n" \
            "end\n" \
            "\n" \
            "def raise_traceback_error\n" \
            "  if $!.message.size >= 900\n" \
            "    File.open('traceback.log', 'w') { |f| f.write($!) }\n" \
            "    raise 'Traceback is too big. Output in traceback.log'\n" \
            "  else\n" \
            "    raise\n" \
            "  end\n" \
            "end\n\n"
        return traceback_report
    end

    def self.get_script_loader
        script_loader = "#{traceback_report}" \
            "def load_scripts_from_folder(path)\n" \
            "  puts Dir.pwd\n" \
            "  files   = []\n" \
            "  folders = []\n" \
            "  Dir.foreach(path) do |f|\n" \
            "    next if f == '.' || f == '..'\n" \
            "    (File.directory?(path + \"/\" + f)) ? folders.push(f) :  files.push(f)\n" \
            "  end\n" \
            "  files.sort!\n" \
            "  files.each do |f|\n" \
            "    code = File.open(path + \"/\" + f, \"r\") { |file| file.read }\n" \
            "    begin\n" \
            "      eval(code, nil, f)\n" \
            "    rescue ScriptError\n" \
            "      raise ScriptError.new($!.message)\n" \
            "    rescue\n" \
            "      $!.message.sub!($!.message, traceback_report)\n" \
            "      raise_traceback_error\n" \
            "    end\n" \
            "  end\n" \
            "  folders.sort!\n" \
            "  folders.each do |folder|\n" \
            "    load_scripts_from_folder(path + \"/\" + folder)\n" \
            "  end\n" \
            "end\n" \
            "\n" \
            "load_scripts_from_folder(File.join(\"Data\", \"Scripts\"))"
        return script_loader
    end

    def self.get_yaml_loader
        yaml_loader = "#{traceback_report}" \
            "def load_yaml_from_folder(path)\n" \
            "  files   = []\n" \
            "  folders = []\n" \
            "  Dir.foreach(path) do |f|\n" \
            "    next if f == '.' || f == '..'\n" \
            "    (File.directory?(path + \"/\" + f)) ? folders.push(f) :  files.push(f)\n" \
            "  end\n" \
            "  files.sort!\n" \
            "  files.each do |f|\n" \
            "    code = File.open(path + \"/\" + f, \"r\") { |file| file.read }\n" \
            "    begin\n" \
            "      eval(code, nil, f)\n" \
            "    rescue ScriptError\n" \
            "      raise ScriptError.new($!.message)\n" \
            "    rescue\n" \
            "      $!.message.sub!($!.message, traceback_report)\n" \
            "      raise_traceback_error\n" \
            "    end\n" \
            "  end\n" \
            "  folders.sort!\n" \
            "  folders.each do |folder|\n" \
            "    load_yaml_from_folder(path + \"/\" + folder)\n" \
            "  end\n" \
            "end\n" \
            "\n" \
            "load_yaml_from_folder(File.join(\"Data\", \"Scripts\"))"
        return yaml_loader
    end

end
