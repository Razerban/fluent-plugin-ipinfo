$LOAD_PATH.unshift(File.join(__dir__, '..', 'lib'))
$LOAD_PATH.unshift(__dir__)
require 'fluent/test'
require 'fluent/test/driver/output'
require 'fluent/test/helpers'

Test::Unit::TestCase.include(Fluent::Test::Helpers)

require 'fluent/plugin/filter_ipinfo'