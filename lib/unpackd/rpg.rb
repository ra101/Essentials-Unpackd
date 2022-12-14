# Copyright (c) 2013 Howard Jeng
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

require 'unpackd/basic_coder'

module RPG
  class System
    include Unpackd::BasicCoder
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
