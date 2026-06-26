# Icinga2 API Client

[![GitHub license](https://img.shields.io/github/license/jbox-web/icinga2-api-client.svg)](https://github.com/jbox-web/icinga2-api-client/blob/master/LICENSE)
[![CI](https://github.com/jbox-web/icinga2-api-client/workflows/CI/badge.svg)](https://github.com/jbox-web/icinga2-api-client/actions)
[![Code Climate](https://codeclimate.com/github/jbox-web/icinga2-api-client/badges/gpa.svg)](https://codeclimate.com/github/jbox-web/icinga2-api-client)
[![Test Coverage](https://codeclimate.com/github/jbox-web/icinga2-api-client/badges/coverage.svg)](https://codeclimate.com/github/jbox-web/icinga2-api-client/coverage)

A Ruby gem to interact easily with the [Icinga2 API](https://www.icinga.com/docs/icinga2/latest/doc/12-icinga2-api/).

It exposes a small, chainable object model on top of the REST API:

```ruby
client.hosts.find('web01').services.find('ssh').schedule_downtime(...)
```

Largely copied (and adapted) from [gdi/ruby-nagios-api-client](https://github.com/gdi/ruby-nagios-api-client).

## Table of contents

- [Requirements](#requirements)
- [Install](#install)
- [Getting started](#getting-started)
- [Configuration](#configuration)
- [Usage](#usage)
  - [Hosts](#hosts)
  - [Services](#services)
  - [Downtimes](#downtimes)
- [Development](#development)
- [Contribute](#contribute)
- [License](#license)

## Requirements

- Ruby >= 3.2 (also tested on JRuby and TruffleRuby)
- An Icinga2 instance with the [API feature](https://icinga.com/docs/icinga-2/latest/doc/12-icinga2-api/#setting-up-the-api) enabled and an API user

## Install

Add it to your `Gemfile`:

```ruby
gem 'icinga2-api-client'
```

Then run `bundle install`, or install it directly:

```sh
gem install icinga2-api-client
```

## Getting started

```ruby
require 'icinga2/api'

client = Icinga2::API::Client.new('https://icinga.example.net:5665',
  version:  'v1',
  username: 'admin',
  password: 'pass'
)

client.hosts.all              # => [#<Icinga2::API::Host>, ...]
client.hosts.find('web01')    # => #<Icinga2::API::Host> (or nil if not found)
```

`Client.new` takes the base URL of the API and an options hash. The options are
passed through to the underlying connection (see [Configuration](#configuration)).

Every object exposes its raw Icinga2 attributes through method calls and as a
hash:

```ruby
host = client.hosts.find('web01')
host.name          # => "web01"
host.state         # => 1.0
host.to_h          # => { name: "web01", state: 1.0, ... }
host.to_h(only: [:name, :state])
host.to_h(except: [:vars])
```

## Configuration

Options passed to `Icinga2::API::Client.new` (second argument):

| Option        | Default | Description                                                              |
| ------------- | ------- | ------------------------------------------------------------------------ |
| `username`    | —       | API user (required, HTTP basic auth)                                     |
| `password`    | —       | API user password (required)                                            |
| `version`     | `'v1'`  | API version segment used in request paths                                |
| `ssl_options` | `{}`    | Hash forwarded to Faraday's `:ssl` option                                |
| `logging`     | `{}`    | Request logging, see below                                               |

### SSL / TLS

`ssl_options` is forwarded verbatim to [Faraday's `ssl` option](https://lostisland.github.io/faraday/#/customization/ssl-options).
To talk to an instance with a self-signed certificate, disable verification:

```ruby
client = Icinga2::API::Client.new('https://icinga.example.net:5665',
  username:    'admin',
  password:    'pass',
  ssl_options: { verify: false }
)
```

To pin a CA bundle instead:

```ruby
ssl_options: { ca_file: '/etc/icinga2/ca.crt' }
```

### Logging

Pass a logger to trace HTTP requests/responses (Faraday's logger middleware):

```ruby
require 'logger'

client = Icinga2::API::Client.new('https://icinga.example.net:5665',
  username: 'admin',
  password: 'pass',
  logging: {
    enabled: true,
    logger:  Logger.new($stdout),
    options: { headers: true, bodies: true }
  }
)
```

## Usage

The examples below assume a configured `client` and `require 'yaml'` for the
`YAML.dump` calls used to pretty-print objects.

### Hosts

```ruby
# All hosts (Array of Icinga2::API::Host)
puts YAML.dump client.hosts.all.map(&:to_s)

# A single host by name (Icinga2::API::Host, or nil)
puts YAML.dump client.hosts.find('web01').to_s
```

### Services

```ruby
# All services of a host (Array of Icinga2::API::Service)
puts YAML.dump client.hosts.find('web01').services.all.map(&:to_s)

# A single service by name
puts YAML.dump client.hosts.find('web01').services.find('ssh').to_s
```

### Downtimes

#### Schedule a downtime

```ruby
require 'active_support/all' # for 1.hour

duration   = 1.hour
start_time = DateTime.now
end_time   = start_time + duration

# Icinga expects Unix timestamps, so call #to_i on the times.
# The `duration` param is mandatory even when `fixed` is true (the default).
client.hosts
      .find('web01')
      .services
      .find('ssh')
      .schedule_downtime(
        author:     'admin',
        comment:    'Maintenance window',
        start_time: start_time.to_i,
        end_time:   end_time.to_i,
        duration:   duration.to_i
      )
```

#### List downtimes

```ruby
# All downtimes of every service on a host
client.hosts.find('web01').services.downtimes

# Downtimes of a single service
client.hosts.find('web01').services.find('ssh').downtimes
```

#### Cancel a downtime

```ruby
client.hosts
      .find('web01')
      .services
      .find('http')
      .downtimes
      .first
      .cancel
```

## Development

```sh
bundle install     # install dependencies
bin/rspec          # run the test suite (uses VCR cassettes, no live server needed)
bin/rubocop        # lint
bin/guard          # watch files and re-run specs on change
```

## Contribute

You can contribute to this gem in many ways, such as:

- Helping with documentation
- Contributing code (features or bugfixes)
- Reporting a bug
- Submitting translations

A big thank you to [all the contributors](https://github.com/jbox-web/icinga2-api-client/graphs/contributors),
and to [gdi/ruby-nagios-api-client](https://github.com/gdi/ruby-nagios-api-client) for the inspiration.

## License

Released under the [MIT License](LICENSE).
