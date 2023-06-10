require 'fluent/plugin/filter'
require 'ipinfo'

class ::Hash
  def stringify_keys
    h = self.map do |k,v|
      v_str = if v.instance_of? Hash
                v.stringify_keys
              else
                v
              end

      [k.to_s, v_str]
    end
    Hash[h]
  end
end

module Fluent::Plugin
  class IPinfoFilter < Fluent::Plugin::Filter
    # Register this filter as "passthru"
    Fluent::Plugin.register_filter('ipinfo', self)

    desc 'IPInfo API access token (Paid plan).'
    config_param :access_token, :string, secret: true, :default => nil

    desc 'The name of the key containing the IP address.'
    config_param :key_name, :string, :default => 'ip_address'

    desc 'The name of the key to store the geographical location data in.'
    config_param :out_key, :string, :default => 'ipinfo'

    desc 'The list of fields to fetch from ipinfo.'
    config_param :fields, :array, value_type: :string, :default => ['country_name', 'region', 'city', 'latitude', 'longitude']

    def initialize
      super
      # Keep the data in cache for one week
      # Number of entries to keep in cache
      @ipinfo_cache_settings = {:ttl => 60 * 60 * 24 * 7, :maxsize => 4096}
    end

    def configure(conf)
      super

      if !@access_token.nil? and @access_token.strip.empty?
        log.warn "access_token value is an empty string. Falling back to default value."
        @access_token = nil
      end

      if @key_name.nil? or @key_name.strip.empty?
        log.warn "key_name value is '#{@key_name}'. Falling back to default value."
        @key_name = 'ip_address'
      end

      if @out_key.nil? or @out_key.strip.empty?
        log.warn "out_key value is '#{@out_key}'. Falling back to default value."
        @out_key = 'ipinfo'
      end

      # Delete duplicates and empty fields (nil values included)
      @fields = @fields.uniq.delete_if {|f| f.strip.empty? or f.nil?}

      unless @fields.length() > 0
        raise Fluent::ConfigError, "Fields array is empty. You need to specify at least one field."
      end

      # Create the IPInfo client handler
      unless @access_token.nil?
        @ipinfo_handler = IPinfo::create(@access_token, @ipinfo_cache_settings)
      else
        @ipinfo_handler = IPinfo::create(nil, @ipinfo_cache_settings)
      end
    end

    def filter(tag, time, record)
      # Check that the record has a key whose name is the value of @key_name
      unless record.key?(@key_name)
        log.error "key '#{@key_name}' is not present in the record. Ignoring the record."
      else
        ip_address = record[@key_name]
        # Check that the ip_address is not 'nil'
        unless ip_address.nil?
          begin
            # Fetch geolocation details using IPInfo API
            ipinfo_details = @ipinfo_handler.details(ip_address)
            # IPInfo ruby wrapper returns a dict based on symbols, we need to stringify the symbols
            # to be able to use them easily
            all_details = ipinfo_details.all
            geodata = all_details.stringify_keys
            # Get the final list of fields by running a join operation on the fields provided by the user and the ones
            # returned by IPInfo API
            ipinfo_returned_fields = geodata.keys
            final_fields = ipinfo_returned_fields & @fields
            if final_fields.length() != @fields.length()
              ignored_fields = @fields - final_fields
              ignored_fields.each{|field|
                log.warn "Field '#{@field}' not present in IPInfo payload. Ignoring it."
              }
            end
            # Extract a subhash from the geolocation data returned by IPInfo API using the final_fields list as keys.
            record[@out_key] = extract_subhash(geodata, final_fields)
          rescue Exception => e
            log.error 'An error occured while fetching geographical location data.', error: e
            log.warn_backtrace e.backtrace
          end
        end
      end
      record
    end

    def extract_subhash(h, a=[])
      h.select {|k, v| a.include?(k) }
    end
  end
end