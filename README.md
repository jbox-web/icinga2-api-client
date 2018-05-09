# Icinga2 API Client

[![GitHub license](https://img.shields.io/github/license/jbox-web/icinga2-api-client.svg)](https://github.com/jbox-web/icinga2-api-client/blob/master/LICENSE)
[![Build Status](https://travis-ci.org/jbox-web/icinga2-api-client.svg?branch=master)](https://travis-ci.org/jbox-web/icinga2-api-client)
[![Code Climate](https://codeclimate.com/github/jbox-web/icinga2-api-client/badges/gpa.svg)](https://codeclimate.com/github/jbox-web/icinga2-api-client)
[![Test Coverage](https://codeclimate.com/github/jbox-web/icinga2-api-client/badges/coverage.svg)](https://codeclimate.com/github/jbox-web/icinga2-api-client/coverage)

A Ruby gem to interact easily with the Icinga2 API.

Largely copied (and adapted) from [gdi/ruby-nagios-api-client](https://github.com/gdi/ruby-nagios-api-client).

## Install

```sh
gem install icinga2-api-client
```

## Usage

```ruby
require 'yaml'
require 'icinga2/api'

client = Icinga2::API::Client.new('https://icinga.example.net:5665',
  version: 'v1',
  username: 'admin',
  password: 'pass',
  verify_ssl: false
)

# Get all hosts. It returns a list of Icinga2::API:Host objects
puts YAML.dump client.hosts.all.map(&:to_s)

# Find host by name. It returns a Icinga2::API:Host object
puts YAML.dump client.hosts.find('my.host.net').to_s

# Get all services for host. It returns a list of Icinga2::API:Service objects
puts YAML.dump client.hosts.find('my.host.net').services.all.map(&:to_s)

# Find service by name. It returns a Icinga2::API:Service object
puts YAML.dump client.hosts.find('my.host.net').services.find('ssh').to_s

# Create a schedule downtime
# The duration param seems to be mandatory, even with 'fixed' param set to `true` (which is the default value).
duration   = 1.hour
start_time = DateTime.now
end_time   = start_time + duration

ssh_downtime =
  client.hosts
        .find('foo.example.net')
        .services
        .find('ssh')
        .schedule_downtime(
          author:     'admin',
          comment:    'ok',
          start_time: start_time.to_i, # Icinga wants timestamps so call to_i
          end_time:   end_time.to_i,   # Icinga wants timestamps so call to_i
          duration:   duration.to_i    # Icinga wants timestamps so call to_i
        )

http_downtime =
  client.hosts
        .find('foo.example.net')
        .services
        .find('http')
        .schedule_downtime(
          author:     'admin',
          comment:    'ok',
          start_time: start_time.to_i, # Icinga wants timestamps so call to_i
          end_time:   end_time.to_i,   # Icinga wants timestamps so call to_i
          duration:   duration.to_i    # Icinga wants timestamps so call to_i
        )

# Get all downtimes across all services. It returns a list of Icinga2::API:Downtime objects
all_downtimes =
  client.hosts
        .find('foo.example.net')
        .services
        .downtimes

# Get all downtimes for one service. It returns a list of Icinga2::API:Downtime objects
all_ssh_downtimes =
  client.hosts
        .find('foo.example.net')
        .services
        .find('ssh')
        .downtimes

all_http_downtimes =
  client.hosts
        .find('foo.example.net')
        .services
        .find('http')
        .downtimes

# Cancel a downtime
client.hosts
      .find('foo.example.net')
      .services
      .find('http')
      .downtimes
      .first
      .cancel
```

## Contributors

A big thank to [them](https://github.com/jbox-web/icinga2-api-client/graphs/contributors) for their contribution!

And a big thank to [gdi/ruby-nagios-api-client](https://github.com/gdi/ruby-nagios-api-client) for the inspiration.

## Contribute

You can contribute to this plugin in many ways such as :
* Helping with documentation
* Contributing code (features or bugfixes)
* Reporting a bug
* Submitting translations
