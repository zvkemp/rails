module ActiveRecord
  # This module has constants for string literals whose extraction has proven to
  # be worthwhile. This set should be minimal, new constants can only be added
  # if proved to make a difference in benchmarks using production applications.
  #
  # String pools are private and they can change anytime.
  module StringPool # :nodoc:
    COMMA      = ','.freeze
    DOT        = '.'.freeze
    EMPTY      = ''.freeze
    UNDERSCORE = '_'.freeze

    ATTRIBUTES   = 'attributes'.freeze
    COLUMN_TYPES = 'column_types'.freeze
    ID           = 'id'.freeze
    NULL         = 'NULL'.freeze
    SCHEMA       = 'SCHEMA'.freeze
    SQL          = 'SQL'.freeze
  end
end
