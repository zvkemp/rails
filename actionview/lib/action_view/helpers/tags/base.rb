module ActionView
  module Helpers
    module Tags # :nodoc:
      class Base # :nodoc:
        include Helpers::ActiveModelInstanceTag, Helpers::TagHelper, Helpers::FormTagHelper
        include FormOptionsHelper

        attr_reader :object

        def initialize(object_name, method_name, template_object, options = {})
          @object_name, @method_name = object_name.to_s.dup, method_name.to_s.dup
          @template_object = template_object

          @object_name.sub!(/\[\]$/,StringPool::EMPTY) || @object_name.sub!(/\[\]\]$/,"]")
          @object = retrieve_object(options.delete(:object))
          @options = options
          @auto_index = retrieve_autoindex(Regexp.last_match.pre_match) if Regexp.last_match
        end

        # This is what child classes implement.
        def render
          raise NotImplementedError, "Subclasses must implement a render method"
        end

        private

        def value(object)
          object.send @method_name if object
        end

        def value_before_type_cast(object)
          unless object.nil?
            method_before_type_cast = @method_name + "_before_type_cast"

            object.respond_to?(method_before_type_cast) ?
              object.send(method_before_type_cast) :
              value(object)
          end
        end

        def retrieve_object(object)
          if object
            object
          elsif @template_object.instance_variable_defined?("@#{@object_name}")
            @template_object.instance_variable_get("@#{@object_name}")
          end
        rescue NameError
          # As @object_name may contain the nested syntax (item[subobject]) we need to fallback to nil.
          nil
        end

        def retrieve_autoindex(pre_match)
          object = self.object || @template_object.instance_variable_get("@#{pre_match}")
          if object && object.respond_to?(:to_param)
            object.to_param
          else
            raise ArgumentError, "object[] naming but object param and @object var don't exist or don't respond to to_param: #{object.inspect}"
          end
        end

        def add_default_name_and_id_for_value(tag_value, options)
          if tag_value.nil?
            add_default_name_and_id(options)
          else
            specified_id = options[StringPool::ID]
            add_default_name_and_id(options)

            if specified_id.blank? && options[StringPool::ID].present?
              options[StringPool::ID] += "_#{sanitized_value(tag_value)}"
            end
          end
        end

        def add_default_name_and_id(options)
          if options.has_key?("index")
            options[StringPool::NAME] ||= options.fetch(StringPool::NAME){ tag_name_with_index(options["index"], options["multiple"]) }
            options[StringPool::ID] = options.fetch(StringPool::ID){ tag_id_with_index(options["index"]) }
            options.delete("index")
          elsif defined?(@auto_index)
            options[StringPool::NAME] ||= options.fetch(StringPool::NAME){ tag_name_with_index(@auto_index, options["multiple"]) }
            options[StringPool::ID] = options.fetch(StringPool::ID){ tag_id_with_index(@auto_index) }
          else
            options[StringPool::NAME] ||= options.fetch(StringPool::NAME){ tag_name(options["multiple"]) }
            options[StringPool::ID] = options.fetch(StringPool::ID){ tag_id }
          end

          options[StringPool::ID] = [options.delete('namespace'), options[StringPool::ID]].compact.join(StringPool::UNDERSCORE).presence
        end

        def tag_name(multiple = false)
          "#{@object_name}[#{sanitized_method_name}]#{"[]" if multiple}"
        end

        def tag_name_with_index(index, multiple = false)
          "#{@object_name}[#{index}][#{sanitized_method_name}]#{"[]" if multiple}"
        end

        def tag_id
          "#{sanitized_object_name}_#{sanitized_method_name}"
        end

        def tag_id_with_index(index)
          "#{sanitized_object_name}_#{index}_#{sanitized_method_name}"
        end

        def sanitized_object_name
          @sanitized_object_name ||= @object_name.gsub(/\]\[|[^-a-zA-Z0-9:.]/, StringPool::UNDERSCORE).sub(/_$/, StringPool::EMPTY)
        end

        def sanitized_method_name
          @sanitized_method_name ||= @method_name.sub(/\?$/,StringPool::EMPTY)
        end

        def sanitized_value(value)
          value.to_s.gsub(/\s/, StringPool::UNDERSCORE).gsub(/[^-\w]/, StringPool::EMPTY).downcase
        end

        def select_content_tag(option_tags, options, html_options)
          html_options = html_options.stringify_keys
          add_default_name_and_id(html_options)
          options[:include_blank] ||= true unless options[:prompt] || select_not_required?(html_options)
          value = options.fetch(:selected) { value(object) }
          select = content_tag("select", add_options(option_tags, options, value), html_options)

          if html_options["multiple"] && options.fetch(:include_hidden, true)
            tag("input", :disabled => html_options["disabled"], :name => html_options[StringPool::NAME], :type => StringPool::HIDDEN, :value => StringPool::EMPTY) + select
          else
            select
          end
        end

        def select_not_required?(html_options)
          !html_options["required"] || html_options["multiple"] || html_options["size"].to_i > 1
        end

        def add_options(option_tags, options, value = nil)
          if options[:include_blank]
            option_tags = content_tag_string('option', options[:include_blank].kind_of?(String) ? options[:include_blank] : nil, :value => StringPool::EMPTY) + StringPool::NEWLINE + option_tags
          end
          if value.blank? && options[:prompt]
            option_tags = content_tag_string('option', prompt_text(options[:prompt]), :value => StringPool::EMPTY) + StringPool::NEWLINE + option_tags
          end
          option_tags
        end
      end
    end
  end
end
