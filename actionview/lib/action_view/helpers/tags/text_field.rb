module ActionView
  module Helpers
    module Tags # :nodoc:
      class TextField < Base # :nodoc:
        def render
          options = @options.stringify_keys
          options["size"] = options["maxlength"] unless options.key?("size")
          options[StringPool::TYPE] ||= field_type
          options[StringPool::VALUE] = options.fetch(StringPool::VALUE) { value_before_type_cast(object) } unless field_type == "file"
          options[StringPool::VALUE] &&= ERB::Util.html_escape(options[StringPool::VALUE])
          add_default_name_and_id(options)
          tag(StringPool::INPUT, options)
        end

        class << self
          def field_type
            @field_type ||= self.name.split("::").last.sub("Field", StringPool::EMPTY).downcase
          end
        end

        private

        def field_type
          self.class.field_type
        end
      end
    end
  end
end
