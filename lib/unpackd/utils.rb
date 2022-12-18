# Copyright (c) 2015 Rachel Wall
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

module Unpackd
  # Defines various utility methods for use by `unpackd`.
  module Utils

    def self.get_rxfile_paths(filenames, dir)
      file_paths, data_dir =  [], File.join(File.realpath(dir), 'Data')
      filenames.each do |fname|
        fname = File.basename(fname, ".*") << '.rxdata'
        file_paths += Dir[File.join(data_dir, fname)]
      end
      return file_paths.uniq
    end

    def self.get_ymlfile_paths(filenames, dir)
      file_paths, data_dir =  [], File.join(File.join(File.realpath(dir), 'Data'), 'YAML')
      filenames.each do |fname|
        fname = File.basename(fname).delete_prefix(".yaml")
        file_paths += Dir[File.join(data_dir, "#{fname}.yaml")]
      end
      return file_paths.uniq
    end

    # Check if the project dir has `Game.rxproj`
    def self.invalid_project?(directory)
      file = Dir["#{File.join(File.expand_path(directory), 'Game.rxproj')}"][0]
      return file == "Game.rxproj"
    end

    # @param options [Hash{Symbol=>Object}] the options hash to check for
    #   combined actions
    # @return [Boolean] `true` if the given options contain a combined action,
    #   `false` otherwise
    def self.combined_action?(options)
      action_count = 0
      # action_count += 1 if options[:yml2rb]
      action_count += 1 if options[:extract]
      action_count += 1 if options[:combine]
      action_count += 1 if options[:revert]
      return action_count > 1
    end

    module Collections
      # Converts the given `array` into a `Hash`.
      #
      # @param array [Array] the array to convert into a hash
      # @return [Hash] the converted hash
      def array_to_hash(array)
        {}.tap do |hash|
          array.each_with_index do |value, index|
            next if (result = block_given? ? yield(value) : value).nil?
            hash[index] = result
          end
          hash[array.size - 1] ||= nil unless array.empty?
        end
      end

      # Converts the given `hash` into an `Array`.
      #
      # @param hash [Hash] the hash to convert into an array
      # @return [Array] the converted array
      def hash_to_array(hash)
        [].tap { |array| hash.each { |index, value| array[index] = value } }
      end
    end

    module BasicCoder
      INCLUDED_CLASSES = []

      def self.included(other)
        INCLUDED_CLASSES << other
      end

      def encode_with(coder)
        ivars.each do |ivar|
          name  = ivar[1..-1]
          value = instance_variable_get(ivar)
          coder[name] = encode(name, value)
        end
      end

      def encode(_, value)
        value
      end

      def init_with(coder)
        coder.map.each do |ivar, value|
          instance_variable_set(:"@#{ivar}", decode(ivar, value))
        end
      end

      def decode(_, value)
        value
      end

      def ivars
        instance_variables
      end

      def self.set_ivars_methods()
        INCLUDED_CLASSES.each do |c|
          RGSS.reset_method(c, :ivars, -> { instance_variables.sort })
        end
      end
    end
  end
end
