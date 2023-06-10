# fluent-plugin-ipinfo

Fluentd Filter plugin to add information about geographical location of IP addresses using the [IPInfo API](https://ipinfo.io/).

## Installation

Install with `fluent-gem` or td-agent provided command as:

```bash
# For fluentd
$ gem install fluent-plugin-ipinfo
# or
$ fluent-gem install fluent-plugin-ipinfo

# For td-agent
$ sudo td-agent-gem install fluent-plugin-ipinfo
```

For more details, see [Plugin Management](https://docs.fluentd.org/deployment/plugin-management)

## Example Configurations

```xml
<filter foo.bar>
  @type ipinfo
  access_token 1a2b3c4d5e
  key_name ip_address
  out_key ipinfo
  fields ["country_name", "region", "city", "latitude", "longitude"]
</filter>
```

In this example, the following event:

```json
{
    "message":"Can you get me the geographical location for this IP addresse ?",
    "ip_address":"8.8.8.8"
}
```

Would be enriched and returned as following:

```json
{
    "message": "Can you get me the geographical location for this IP addresse ?",
    "ip_address": "8.8.8.8",
    "ipinfo": {
        "country_name": "United States",
        "region": "California",
        "city": "Mountain View",
        "latitude": "37.4056",
        "longitude": "-122.0775"
    }
}
```

## Parameters

[Common Parameters](https://docs.fluentd.org/configuration/plugin-common-parameters)

### `access_token`

| type | required | default |
| :--- | :--- | :--- |
| string | false | `nil` |

The token to be used with the IPInfo API for paid plans.
To use the free plan (limited to 50k requests per month), do not use the `access_token` parameter.

### `key_name`

| type | required | default |
| :--- | :--- | :--- |
| string | false | `ip_address` |

The name of the key containing the IP address.

### `out_key`

| type | required | default |
| :--- | :--- | :--- |
| string | false | `ipinfo` |

The name of the key to store the geographical location data in.

### `fields`

| type | required | default |
| :--- | :--- | :--- |
| array | false | `["country_name", "region", "city", "latitude", "longitude"]` |

The list of fields to fetch from IPInfo. The [full list of fields](https://github.com/ipinfo/ruby#accessing-all-properties) is described in the [official IPInfo API Ruby client](https://github.com/ipinfo/ruby).

## Learn More

* [Filter Plugin Overview](https://docs.fluentd.org/filter)
* [IPInfo](https://ipinfo.io/)
* [Official IPInfo API Ruby client](https://github.com/ipinfo/ruby)

## Copyright

Copyright :  Copyright (c) 2023 - Ahmed Abdelkafi
License   :  Apache License, Version 2.0
