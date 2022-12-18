# This file contains significant portions of Psych 2.0.0 to modify behavior and
# to fix bugs. The license follows:
#
# Copyright 2009 Aaron Patterson, et al.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

gem 'psych', '2.0.0'
require 'psych'

if defined?(Psych::VERSION) && Psych::VERSION == '2.0.0'
  # `Psych` bugs:
  #
  # 1) `Psych` has a bug where it stores an anchor to the YAML for an object,
  # but indexes the reference by `object_id`. This doesn't keep the object
  # alive, so if it gets garbage collected, Ruby might generate an object with
  # the same `object_id` and try to generate a reference to the stored anchor.
  # This monkey-patches the `Registrar` to keep the object alive so incorrect
  # references aren't generated. The bug is also present in `Psych` 1.3.4, but
  # there isn't a convenient way to patch that.
  #
  # 2) `Psych` also doesn't create references and anchors for classes that
  # implement `encode_with`. This modifies `dump_coder` to handle that
  # situation.
  #
  # Added two options:
  # `:flow_classes` - array of class types that will automatically emit with
  #   flow style rather than block style
  module Psych
    module Visitors
      class YAMLTree < Psych::Visitors::Visitor
        class Registrar
          alias_method :unpackd_original_initialize, :initialize
          def initialize
            unpackd_original_initialize
            @obj_to_obj = {}
          end

          alias_method :unpackd_original_register, :register
          def register(target, node)
            unpackd_original_register(target, node)
            @obj_to_obj[target.object_id] = target
          end
        end

        def visit_Hash(object)
          tag   = object.class == ::Hash ? nil : "!ruby/hash:#{object.class}"
          style = Nodes::Mapping::BLOCK
          register(object, @emitter.start_mapping(nil, tag, !tag, style))
          object.keys.sort!.each do |key|
            accept(key) && accept(object[key])
          end
          @emitter.end_mapping
        end

        def visit_Object(object)
          unless (tag = Psych.dump_tags[object.class])
            klass = object.class == ::Object ? nil : object.class.name
            tag   = ['!ruby/object', klass].compact.join(':')
          end

          style =
            if $FLOW_CLASSES.include?(object.class)
              Nodes::Mapping::FLOW
            else
              Nodes::Mapping::BLOCK
            end

          register(object, @emitter.start_mapping(nil, tag, false, style))
          dump_ivars(object)
          @emitter.end_mapping
        end

        def dump_coder(object)
          @coders << object
          unless (tag = Psych.dump_tags[object.class])
            klass = object.class == ::Object ? nil : object.class.name
            tag   = ['!ruby/object', klass].compact.join(':')
          end
          object.encode_with(coder = Psych::Coder.new(tag))
          register(object, emit_coder(coder))
        end

        def dump_ivars(target)
          ivars = find_ivars(target)
          ivars.sort!.each do |ivar|
            name = ivar[1..-1]
            @emitter.scalar(name, nil, nil, true, false, Nodes::Scalar::ANY)
            accept(target.instance_variable_get(ivar))
          end
        end
      end
    end
  end
else
  warn 'Warning: Psych 2.0.0 not detected.'
end
