# Copyright (c) 2013 Howard Jeng
# Copyright (c) 2015 Rachel Wall
# Copyright (c) 2022 Parth Agarwal
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
require 'unpackd/psych'
require 'unpackd/utils'
require 'scanf'

class Table
  def initialize(bytes)
    @dim, @x, @y, @z, size, *@data = bytes.unpack('L5S*')
    unless size == @data.length && (@x * @y * @z == size)
      raise 'Size mismatch loading Table from data'
    end
  end

  def encode_with(coder)
    coder.style = Psych::Nodes::Mapping::BLOCK

    coder['dim'] = @dim
    coder['x']   = @x
    coder['y']   = @y
    coder['z']   = @z

    if @x * @y * @z > 0
      stride = @x < 2 ? (@y < 2 ? @z : @y) : @x
      rows = @data.each_slice(stride).to_a
      rows.map! { |x| x.map! { |y| '%04x' % y }.join(' ') }
      coder['data'] = rows
    else
      coder['data'] = []
    end
  end

  def init_with(coder)
    @dim  = coder['dim']
    @x    = coder['x']
    @y    = coder['y']
    @z    = coder['z']
    @data = coder['data'].flat_map { |x| x.split.map(&:hex) }
    items = @x * @y * @z
    raise 'Size mismatch loading Table from YAML' unless items == @data.length
  end

  def _dump(_depth = 0)
    [@dim, @x, @y, @z, @x * @y * @z, *@data].pack('L5S*')
  end

  def self._load(bytes)
    Table.new(bytes)
  end
end

class PBAnimations < Array
end

class PBAnimation < Array
end

class Color
  def initialize(bytes)
    @red, @green, @blue, @alpha = *bytes.unpack('D4')
  end

  def _dump(_depth = 0)
    [@red, @green, @blue, @alpha].pack('D4')
  end

  def self._load(bytes)
    Color.new(bytes)
  end
end

class Tone
  def initialize(bytes)
    @red, @green, @blue, @gray = *bytes.unpack('D4')
  end

  def _dump(_depth = 0)
    [@red, @green, @blue, @gray].pack('D4')
  end

  def self._load(bytes)
    Tone.new(bytes)
  end
end

class Rect
  def initialize(bytes)
    @x, @y, @width, @height = *bytes.unpack('i4')
  end

  def _dump(_depth = 0)
    [@x, @y, @width, @height].pack('i4')
  end

  def self._load(bytes)
    Rect.new(bytes)
  end
end

module RPG
  class System
    include Unpackd::Utils::BasicCoder
    HASHED_VARS = %w(variables switches)
  end

  def encode(name, value)
    if HASHED_VARS.include?(name)
      array_to_hash(value) { |val| reduce_string(val) }
    elsif name == 'version_id'
      map_version(value)
    else
      value
    end
  end

  def decode(name, value)
    HASHED_VARS.include?(name) ? hash_to_array(value) : value
  end

  class EventCommand
    def encode_with(coder)
      unless instance_variables.length == 3
        raise 'Unexpected number of instance variables'
      end
      clean

      coder.style =
        case @code
        when MOVE_LIST_CODE then Psych::Nodes::Mapping::BLOCK
        else Psych::Nodes::Mapping::FLOW
        end
      coder['c'] = @code
      coder['i'] = @indent
      coder['p'] = @parameters
    end

    def init_with(coder)
      @code       = coder['c']
      @indent     = coder['i']
      @parameters = coder['p']
    end
  end
end


module RGSS

  # creates an empty class in a potentially nested scope
  def self.process(root, name, *args)
    if args.length > 0
      process(root.const_get(name), *args)
    else
      root.const_set(name, Class.new) unless root.const_defined?(name, false)
    end
  end

  # RGSS/Essentials data structures
  [
    [:RPG, :Actor], [:RPG, :Animation], [:RPG, :Animation, :Frame],
    [:RPG, :Animation, :Timing],  [:RPG, :Armor], [:RPG, :AudioFile],
    [:RPG, :BGM], [:RPG, :BGS], [:RPG, :Class],[:RPG, :CommonEvent], [:RPG, :Enemy],
    [:RPG, :Enemy, :Action], [:RPG, :Event], [:RPG, :Event, :Page],
    [:RPG, :Event, :Page, :Condition], [:RPG, :Event, :Page, :Graphic],
    [:RPG, :Item], [:RPG, :Map], [:RPG, :MapInfo], [:RPG, :MoveCommand],
    [:RPG, :MoveRoute], [:RPG, :SE], [:RPG, :Skill], [:RPG, :State],
    [:RPG, :System, :TestBattler], [:RPG, :System, :Words], [:RPG, :Tileset],
    [:RPG, :Troop], [:RPG, :Troop, :Page], [:RPG, :Troop, :Page, :Condition],
    [:RPG, :UsableItem], [:RPG, :Weapon], [:PBAnimTiming], [:PBAnimationPlayerX]
   ].each { |x| process(Object, *x) }

   $FLOW_CLASSES = [
     Color, Tone, RPG::BGM, RPG::BGS, RPG::MoveCommand, RPG::SE,
     PBAnimations, PBAnimation, PBAnimTiming
   ]

  def self.remove_defined_method(scope, name)
    if scope.instance_methods(false).include?(name)
      scope.send(:remove_method, name)
    end
  end

  def self.reset_method(scope, name, method)
    remove_defined_method(scope, name)
    scope.send(:define_method, name, method)
  end

  def self.reset_const(scope, sym, value)
    scope.send(:remove_const, sym) if scope.const_defined?(sym)
    scope.send(:const_set, sym, value)
  end

  def self.setup_classes
    reset_method(RPG::System, :reduce_string, lambda do |string|
      return nil if string.nil?
      stripped = string.strip
      stripped.empty? ? nil : stripped
    end)

    # These magic numbers should be different. If they are the same, the
    # saved version of the map in save files will be used instead of any
    # updated version of the map.
    reset_method(RPG::System, :map_version, ->(_) { 12345678 })
    reset_method(Game_System, :map_version, ->(_) { 87654321 })

    # Format event commands to flow style for the event codes that aren't move commands.
    reset_method(RPG::EventCommand, :clean, -> do
      @parameters[0].rstrip! if @code == 401
    end)
    reset_const(RPG::EventCommand, :MOVE_LIST_CODE, 209)

    Unpackd::Utils::BasicCoder.set_ivars_methods
  end

  def self.get_data_dir(base)
    File.join(base, 'Data')
  end

  def self.get_yaml_dir(base)
    File.join(get_data_dir(base), 'YAML')
  end

  def self.get_script_dir(base)
    File.join(get_data_dir(base), 'Scripts')
  end

  def self.get_backup_dir(base)
    File.join(get_data_dir(base), 'Backup')
  end

  class ::Game_Switches
    include Unpackd::Utils::BasicCoder, Unpackd::Utils::Collections

    def encode(_, value)
      array_to_hash(value)
    end

    def decode(_, value)
      hash_to_array(value)
    end
  end

  class ::Game_Variables
    include Unpackd::Utils::BasicCoder, Unpackd::Utils::Collections

    def encode(_, value)
      array_to_hash(value)
    end

    def decode(_, value)
      hash_to_array(value)
    end
  end

  class ::Game_SelfSwitches
    include Unpackd::Utils::BasicCoder

    def encode(_, value)
      Hash[value.map { |(key, val)| next [sprintf('%03d %03d %s', key, val)] }]
    end

    def decode(_, value)
      Hash[value.map { |(key, val)| next [key.scanf('%d %d %s'), val] }]
    end
  end

  class ::Game_System
    include Unpackd::Utils::BasicCoder

    def encode(name, value)
      name == 'version_id' ? map_version(value) : value
    end
  end
end
