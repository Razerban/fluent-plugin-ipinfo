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
  class IPinfoFilter < Filter
    # Register this filter as "passthru"
    Fluent::Plugin.register_filter('ipinfo', self)

    desc 'IPInfo API access token (Paid plan).'
    config_param :access_token, :string, secret: true, :default => nil

    desc 'The name of the key containing the IP address.'
    config_param :key_name, :string, :default => 'ip_address'

    desc 'The name of the key to store the geolocation data in.'
    config_param :out_key, :string, :default => 'ipinfo'

    desc 'The list of fields to fetch from ipinfo.'
    config_param :fields, :array, value_type: :string, :default => ['country_name', 'region', 'city', 'latitude', 'longitude']

    def configure(conf)
      super
      # IPInfo handler:
      # "maxsize": 4096         # Number of entries to keep in cache
      # "ttl": 60 * 60 * 24 * 7 # Keep the data in cache for one week
      @ipinfo_settings = {:ttl => 604800, :maxsize => 4096}
      unless @access_token.nil?
        @ipinfo_handler = IPinfo::create(@access_token, @ipinfo_settings)
      else
        @ipinfo_handler = IPinfo::create(nil, @ipinfo_settings)
      end
    end

    def filter(tag, time, record)
      ip_address = record[@key_name]
      unless ip_address.nil?
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
            log.warn "Field \"" + field + "\" not present in IPInfo payload. Ignoring it."
          }
        end
        # Extract a subhash from the geolocation data returned by IPInfo API using the final_fields list as keys.
        record[@out_key] = extract_subhash(geodata, final_fields)
      end
      record
    end

    def extract_subhash(h, a=[])
      h.select {|k, v| a.include?(k) }
    end
  end
end