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

require 'rvpacker/utils/collections'

module Rvpacker
  # Defines various utility methods for use by `rvpacker`.
  module Utils
    # @param directory [String] the directory to obtain the project type for
    # @return [:xp, :vx, :ace, nil] the project type of the given directory if
    #   it could be determined, `nil` otherwise
    def self.project_type_for(directory)
      case Dir["#{File.expand_path(directory)}/Game.r?proj*"][0]
      when /Game\.rxproj$/  then :xp
      when /Game\.rvproj$/  then :vx
      when /Game\.rvproj2$/ then :ace
      end
    end

    # @param directory [String] the directory to test the validity of
    # @return [Boolean] `true` if the directory is the root of a valid RPG
    #   Maker project, `false` otherwise
    def self.valid_project?(directory)
      file = Dir["#{File.expand_path(directory)}/Game.r?proj*"][0]
      file =~ /Game\.r(?:xproj|vproj2?)$/ ? true : false
    end

    # @param options [Hash{Symbol=>Object}] the options hash to check for
    #   combined actions
    # @return [Boolean] `true` if the given options contain a combined action,
    #   `false` otherwise
    def self.combined_action?(options)
      return true if options[:action] && (options[:pack] || options[:unpack])
      return true if options[:pack] && options[:unpack]
      false
    end
  end
end
