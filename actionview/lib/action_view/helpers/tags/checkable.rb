module ActionView
  module Helpers
    module Tags # :nodoc:
      module Checkable # :nodoc:
        def input_checked?(object, options)
          if options.has_key?(StringPool::CHECKED)
            checked = options.delete StringPool::CHECKED
            checked == true || checked == StringPool::CHECKED
          else
            checked?(value(object))
          end
        end
      end
    end
  end
end
