module ActionView
  # This module has constants for string literals whose extraction has proven to
  # be worthwhile. This set should be minimal, new constants can only be added
  # if proved to make a difference in benchmarks using production applications.
  #
  # String pools are private and they can change anytime.
  module StringPool # :nodoc:
    EMPTY      = ''.freeze
    NEWLINE    = "\n".freeze
    SLASH      = '/'.freeze
    UNDERSCORE = '_'.freeze

    CHECKED  = 'checked'.freeze
    FOR      = 'for'.freeze
    HIDDEN   = 'hidden'.freeze
    HREF     = 'href'.freeze
    ID       = 'id'.freeze
    INDEX    = 'index'.freeze
    INPUT    = 'input'.freeze
    MULTIPLE = 'multiple'.freeze
    NAME     = 'name'.freeze
    TYPE     = 'type'.freeze
    VALUE    = 'value'.freeze
  end
end
