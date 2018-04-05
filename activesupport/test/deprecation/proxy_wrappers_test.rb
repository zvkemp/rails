# frozen_string_literal: true

require "abstract_unit"
require "active_support/deprecation"

class ProxyWrappersTest < ActiveSupport::TestCase
  Waffles     = false
  NewWaffles  = :hamburgers

  class DeprecationSpy
    def warn(message, stack)
      calls << [message, stack]
    end

    def calls
      @calls ||= []
    end
  end

  def test_deprecated_object_proxy_doesnt_wrap_falsy_objects
    proxy = ActiveSupport::Deprecation::DeprecatedObjectProxy.new(nil, "message")
    assert !proxy
  end

  def test_deprecated_instance_variable_proxy_doesnt_wrap_falsy_objects
    proxy = ActiveSupport::Deprecation::DeprecatedInstanceVariableProxy.new(nil, :waffles)
    assert !proxy
  end

  def test_deprecated_constant_proxy_doesnt_wrap_falsy_objects
    proxy = ActiveSupport::Deprecation::DeprecatedConstantProxy.new(Waffles, NewWaffles)
    assert !proxy
  end

  def test_deprecated_object_to_s
    spy = DeprecationSpy.new
    proxy = ActiveSupport::Deprecation::DeprecatedObjectProxy.new(Object.new, "message", spy)
    assert proxy.to_s['#<Object']
    assert spy.calls.count == 1


    #TODO: Delegator includes a stripped-down Kernel
    # with to_enum, enum_for, is_a?, pp, etc defined.
    # see https://github.com/ruby/ruby/blob/trunk/lib/delegate.rb#L40
    #
    # FIXME?
    enum = proxy.to_enum(:to_i)
    assert spy.calls.count == 1
    assert_raises { enum.to_a }

    assert spy.calls.count == 2
  end

  def test_deprecated_instance_variable_proxy_works
    spy = DeprecationSpy.new
    klass = Class.new do
      def initialize(spy)
        @request = ActiveSupport::Deprecation::DeprecatedInstanceVariableProxy.new(self, :request, :@request, spy)
        @_request = :special_request
      end

      def request
        @_request
      end

      def old_request
        @request
      end
    end

    example = klass.new(spy)
    assert example.old_request.to_s == 'special_request'
    assert spy.calls.count == 1
  end
end
