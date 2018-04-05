# frozen_string_literal: true

require "delegate"
require "active_support/core_ext/regexp"

module ActiveSupport
  class Deprecation
    class OldDeprecationProxy
      def self.new(*args, &block)
        object = args.first

        return object unless object
        super
      end

      instance_methods.each { |m| undef_method m unless /^__|^object_id$/.match?(m) }

      # Don't give a deprecation warning on inspect since test/unit and error
      # logs rely on it for diagnostics.
      def inspect
        target.inspect
      end

      private
        def method_missing(called, *args, &block)
          warn caller_locations, called, args
          target.__send__(called, *args, &block)
        end
    end
    class DeprecationProxy < Delegator #:nodoc:
      def self.new(object, *)
        return object unless object
        super
      end

      def initialize(object)
        super
        @_deprecated_object = object
      end

      def __getobj__
        @_deprecated_object
      end

      def __setobj__(obj)
        @_deprecated_object = obj
      end

      # Don't give a deprecation warning on inspect since test/unit and error
      # logs rely on it for diagnostics.
      def inspect
        __getobj__.inspect
      end

      private
        def method_missing(called, *args)
          warn Kernel.caller_locations, called, args
          super
        end
    end

    # DeprecatedObjectProxy transforms an object into a deprecated one. It
    # takes an object, a deprecation message and optionally a deprecator. The
    # deprecator defaults to +ActiveSupport::Deprecator+ if none is specified.
    #
    #   deprecated_object = ActiveSupport::Deprecation::DeprecatedObjectProxy.new(Object.new, "This object is now deprecated")
    #   # => #<Object:0x007fb9b34c34b0>
    #
    #   deprecated_object.to_s
    #   DEPRECATION WARNING: This object is now deprecated.
    #   (Backtrace)
    #   # => "#<Object:0x007fb9b34c34b0>"
    class DeprecatedObjectProxy < DeprecationProxy
      def initialize(object, message, deprecator = ActiveSupport::Deprecation.instance)
        super(object)
        @message = message
        @deprecator = deprecator
      end

      private

        def warn(callstack, called, args)
          @deprecator.warn("called: #{called} #{@message}", callstack)
        end
    end

    # DeprecatedInstanceVariableProxy transforms an instance variable into a
    # deprecated one. It takes an instance of a class, a method on that class
    # and an instance variable. It optionally takes a deprecator as the last
    # argument. The deprecator defaults to +ActiveSupport::Deprecator+ if none
    # is specified.
    #
    #   class Example
    #     def initialize
    #       @request = ActiveSupport::Deprecation::DeprecatedInstanceVariableProxy.new(self, :request, :@request)
    #       @_request = :special_request
    #     end
    #
    #     def request
    #       @_request
    #     end
    #
    #     def old_request
    #       @request
    #     end
    #   end
    #
    #   example = Example.new
    #   # => #<Example:0x007fb9b31090b8 @_request=:special_request, @request=:special_request>
    #
    #   example.old_request.to_s
    #   # => DEPRECATION WARNING: @request is deprecated! Call request.to_s instead of
    #      @request.to_s
    #      (Backtrace information…)
    #      "special_request"
    #
    #   example.request.to_s
    #   # => "special_request"
    class DeprecatedInstanceVariableProxy < DeprecationProxy
      def initialize(owner, accessor_method, variable_name = "@#{accessor_method}", deprecator = ActiveSupport::Deprecation.instance)
        super(owner) # TODO - is this right?
        @owner = owner
        @accessor_method = accessor_method
        @variable_name = variable_name
        @deprecator = deprecator
      end

      # any methods called on this object should delegate to @owner.__send__(@method)

      def __getobj__
        @owner.__send__(@accessor_method)
      end

      private

        def warn(callstack, called, args)
          @deprecator.warn("#{@variable_name} is deprecated! Call #{@accessor_method}.#{called} instead of #{@variable_name}.#{called}. Args: #{args.inspect}", callstack)
        end
    end

    # DeprecatedConstantProxy transforms a constant into a deprecated one. It
    # takes the names of an old (deprecated) constant and of a new constant
    # (both in string form) and optionally a deprecator. The deprecator defaults
    # to +ActiveSupport::Deprecator+ if none is specified. The deprecated constant
    # now returns the value of the new one.
    #
    #   PLANETS = %w(mercury venus earth mars jupiter saturn uranus neptune pluto)
    #
    #   # (In a later update, the original implementation of `PLANETS` has been removed.)
    #
    #   PLANETS_POST_2006 = %w(mercury venus earth mars jupiter saturn uranus neptune)
    #   PLANETS = ActiveSupport::Deprecation::DeprecatedConstantProxy.new('PLANETS', 'PLANETS_POST_2006')
    #
    #   PLANETS.map { |planet| planet.capitalize }
    #   # => DEPRECATION WARNING: PLANETS is deprecated! Use PLANETS_POST_2006 instead.
    #        (Backtrace information…)
    #        ["Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"]
    class DeprecatedConstantProxy < OldDeprecationProxy
      def initialize(old_const, new_const, deprecator = ActiveSupport::Deprecation.instance, message: "#{old_const} is deprecated! Use #{new_const} instead.")
        require "active_support/inflector/methods"

        @old_const = old_const
        @new_const = new_const
        @deprecator = deprecator
        @message = message
      end

      # Returns the class of the new constant.
      #
      #   PLANETS_POST_2006 = %w(mercury venus earth mars jupiter saturn uranus neptune)
      #   PLANETS = ActiveSupport::Deprecation::DeprecatedConstantProxy.new('PLANETS', 'PLANETS_POST_2006')
      #   PLANETS.class # => Array
      def class
        target.class
      end

      private
        def target
          ActiveSupport::Inflector.constantize(@new_const.to_s)
        end

        def warn(callstack, called, args)
          @deprecator.warn(@message, callstack)
        end
    end
  end
end
