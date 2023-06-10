require 'test/unit'
require 'fluent/test/driver/filter'
require 'helper'

require 'fluent/plugin/filter_ipinfo'

class IPinfoFilterTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup # this is required to setup router and others
  end

  # default configuration for tests
  CONFIG = %[
    @type ipinfo
  ]

  def create_driver(config = CONFIG)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::IPinfoFilter).configure(config)
  end

  def test_default_config
    d = create_driver(CONFIG)
    assert_equal d.instance.access_token, nil
    assert_equal d.instance.key_name, 'ip_address'
    assert_equal d.instance.out_key, 'ipinfo'
    assert_equal d.instance.fields, ['country_name', 'region', 'city', 'latitude', 'longitude']
  end

  def test_custom_config
    config = %[
      @type ipinfo
      access_token token
      key_name key
      out_key out
      fields ["field1", "field2"]
    ]
    d = create_driver(config)
    assert_equal d.instance.access_token, 'token'
    assert_equal d.instance.key_name, 'key'
    assert_equal d.instance.out_key, 'out'
    assert_equal d.instance.fields, ['field1', 'field2']
  end

  def filter(config, messages)
    d = create_driver(config)
    d.run(default_tag: 'test') do
      messages.each do |message|
        d.feed(message)
      end
    end
    d.filtered_records
  end

  sub_test_case 'plugin will use default values' do
    test 'access_token nil' do
      config = %[
        @type ipinfo
        access_token
      ]
      d = create_driver(config)
      assert_equal d.instance.access_token, nil
    end

    test 'access_token empty string' do
      config = %[
        @type ipinfo
        access_token ""
      ]
      d = create_driver(config)
      assert_equal d.instance.access_token, nil
    end

    test 'key_name nil' do
      config = %[
        @type ipinfo
        key_name
      ]
      d = create_driver(config)
      assert_equal d.instance.key_name, 'ip_address'
    end

    test 'key_name empty string' do
      config = %[
        @type ipinfo
        key_name
      ]
      d = create_driver(config)
      assert_equal d.instance.key_name, 'ip_address'
    end

    test 'out_key nil' do
      config = %[
        @type ipinfo
        out_key
      ]
      d = create_driver(config)
      assert_equal d.instance.out_key, 'ipinfo'
    end

    test 'out_key empty string' do
      config = %[
        @type ipinfo
        out_key
      ]
      d = create_driver(config)
      assert_equal d.instance.out_key, 'ipinfo'
    end
  end

  sub_test_case 'plugin will raise Fluent::ConfigError' do
    test 'empty fields' do
      config = %[
        @type ipinfo
        fields []
      ]
      assert_raise Fluent::ConfigError do
        create_driver(config)
      end
    end

    test 'fields with one empty string' do
      config = %[
        @type ipinfo
        fields [""]
      ]
      assert_raise Fluent::ConfigError do
        create_driver(config)
      end
    end

    test 'fields with multiple empty string' do
      config = %[
        @type ipinfo
        fields [""]
      ]
      assert_raise Fluent::ConfigError do
        create_driver(config)
      end
    end
  end

  sub_test_case 'plugin will fetch geolocation data' do
    test 'add ipinfo to record with default fields' do
      config = CONFIG
      messages = [
        {
          'ip_address' => '8.8.8.8'
        }
      ]
      expected = [
        {
          'ip_address' => '8.8.8.8',
          'ipinfo' => {
            'country_name' => 'United States',
            'region' => 'California',
            'city' => 'Mountain View',
            'latitude' => '37.4056',
            'longitude' => '-122.0775'
          }
        }
      ]
      filtered_records = filter(config, messages)
      assert_equal(expected, filtered_records)
    end

    test 'add ipinfo to record with custom key_name' do
      config = %[
        @type ipinfo
        key_name ip
      ]
      messages = [
        {
          'ip' => '8.8.8.8'
        }
      ]
      expected = [
        {
          'ip' => '8.8.8.8',
          'ipinfo' => {
            'country_name' => 'United States',
            'region' => 'California',
            'city' => 'Mountain View',
            'latitude' => '37.4056',
            'longitude' => '-122.0775'
          }
        }
      ]
      filtered_records = filter(config, messages)
      assert_equal(expected, filtered_records)
    end

    test 'add ipinfo to record with custom out_key' do
      config = %[
        @type ipinfo
        out_key geodata
      ]
      messages = [
        {
          'ip_address' => '8.8.8.8'
        }
      ]
      expected = [
        {
          'ip_address' => '8.8.8.8',
          'geodata' => {
            'country_name' => 'United States',
            'region' => 'California',
            'city' => 'Mountain View',
            'latitude' => '37.4056',
            'longitude' => '-122.0775'
          }
        }
      ]
      filtered_records = filter(config, messages)
      assert_equal(expected, filtered_records)
    end

    test 'add ipinfo to record with custom out_key that is already defined' do
      config = %[
        @type ipinfo
        out_key geodata
      ]
      messages = [
        {
          'ip_address' => '8.8.8.8',
          'geodata' => 'bye!'
        }
      ]
      expected = [
        {
          'ip_address' => '8.8.8.8',
          'geodata' => {
            'country_name' => 'United States',
            'region' => 'California',
            'city' => 'Mountain View',
            'latitude' => '37.4056',
            'longitude' => '-122.0775'
          }
        }
      ]
      filtered_records = filter(config, messages)
      assert_equal(expected, filtered_records)
    end

    test 'add ipinfo to record with custom fields' do
      config = %[
        @type ipinfo
        fields ["country_name", "city"]
      ]
      messages = [
        {
          'ip_address' => '8.8.8.8'
        }
      ]
      expected = [
        {
          'ip_address' => '8.8.8.8',
          'ipinfo' => {
            'country_name' => 'United States',
            'city' => 'Mountain View'
          }
        }
      ]
      filtered_records = filter(config, messages)
      assert_equal(expected, filtered_records)
    end

    test 'add ipinfo to record with custom key_name and custom fields' do
      config = %[
        @type ipinfo
        key_name ip
        fields ["country_name", "city"]
      ]
      messages = [
        {
          'ip' => '8.8.8.8'
        }
      ]
      expected = [
        {
          'ip' => '8.8.8.8',
          'ipinfo' => {
            'country_name' => 'United States',
            'city' => 'Mountain View'
          }
        }
      ]
      filtered_records = filter(config, messages)
      assert_equal(expected, filtered_records)
    end

    test 'add ipinfo to record with custom key_name and custom out_key' do
      config = %[
        @type ipinfo
        key_name ip
        out_key geodata
      ]
      messages = [
        {
          'ip' => '8.8.8.8'
        }
      ]
      expected = [
        {
          'ip' => '8.8.8.8',
          'geodata' => {
            'country_name' => 'United States',
            'region' => 'California',
            'city' => 'Mountain View',
            'latitude' => '37.4056',
            'longitude' => '-122.0775'
          }
        }
      ]
      filtered_records = filter(config, messages)
      assert_equal(expected, filtered_records)
    end

    test 'add ipinfo to record with custom key_name, custom out_name and custom fields' do
      config = %[
        @type ipinfo
        key_name ip
        out_key geodata
        fields ["country_name", "city"]
      ]
      messages = [
        {
          'ip' => '8.8.8.8'
        }
      ]
      expected = [
        {
          'ip' => '8.8.8.8',
          'geodata' => {
            'country_name' => 'United States',
            'city' => 'Mountain View'
          }
        }
      ]
      filtered_records = filter(config, messages)
      assert_equal(expected, filtered_records)
    end
  end
end