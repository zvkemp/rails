module ActionDispatch
  # This module has constants for string literals whose extraction has proven to
  # be worthwhile. This set should be minimal, new constants can only be added
  # if proved to make a difference in benchmarks using production applications.
  #
  # String pools are private and they can change anytime.
  module StringPool # :nodoc:
    EMPTY = ''.freeze
    SLASH = '/'.freeze

    PATH_INFO   = 'PATH_INFO'.freeze
    SCRIPT_NAME = 'SCRIPT_NAME'.freeze
  end
end
