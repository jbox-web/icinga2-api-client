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
- [Error handling](#error-handling)
- [Thread safety](#thread-safety)
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

| Option         | Default | Description                                                  |
| -------------- | ------- | ------------------------------------------------------------ |
| `username`     | —       | API user (required, HTTP basic auth)                         |
| `password`     | —       | API user password (required)                                 |
| `version`      | `'v1'`  | API version segment used in request paths                    |
| `ssl_options`  | `{}`    | Hash forwarded to Faraday's `:ssl` option                    |
| `open_timeout` | `nil`   | Connection open timeout in seconds (no timeout by default)   |
| `timeout`      | `30`    | Request read timeout in seconds                              |
| `logging`      | `{}`    | Request logging, see below                                   |

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

### Timeouts

The read `timeout` defaults to 30 seconds; `open_timeout` is unset. Override
both (in seconds) to suit your environment:

```ruby
client = Icinga2::API::Client.new('https://icinga.example.net:5665',
  username:     'admin',
  password:     'pass',
  open_timeout: 5,
  timeout:      30
)
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
# Returns the created Icinga2::API::Downtime (raises ArgumentError if a
# required parameter is missing).
downtime =
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

# A whole host can be put in downtime too (same parameters):
client.hosts.find('web01').schedule_downtime(
  author: 'admin', comment: 'Reboot', start_time: start_time.to_i,
  end_time: end_time.to_i, duration: duration.to_i
)
```

#### List downtimes

```ruby
# All downtimes of every service on a host
client.hosts.find('web01').services.downtimes

# Downtimes of a single service
client.hosts.find('web01').services.find('ssh').downtimes

# Host-level downtimes
client.hosts.find('web01').downtimes
```

#### Acknowledge a problem

```ruby
# author and comment are required
client.hosts.find('web01').services.find('ssh').acknowledge(
  author: 'admin', comment: 'Looking into it'
)

# Hosts can be acknowledged too
client.hosts.find('web01').acknowledge(author: 'admin', comment: 'On it')

# Remove an acknowledgement
client.hosts.find('web01').services.find('ssh').remove_acknowledgement
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

## Error handling

Transport errors are wrapped in this gem's own hierarchy so you never have to
rescue Faraday exceptions directly. All of them inherit from
`Icinga2::API::Error`:

| Exception                              | Raised when                          |
| -------------------------------------- | ------------------------------------ |
| `Icinga2::API::Error::NotFound`        | server returned `404`                |
| `Icinga2::API::Error::ClientError`     | server returned another `4xx`        |
| `Icinga2::API::Error::ServerError`     | server returned a `5xx`              |
| `Icinga2::API::Error::Timeout`         | the request timed out                |
| `Icinga2::API::Error::ConnectionFailed`| the connection could not be opened   |

```ruby
begin
  client.hosts.find('web01').services.find('ssh').schedule_downtime(...)
rescue Icinga2::API::Error => e
  warn "Icinga2 request failed: #{e.message}"
end
```

> `Client#hosts.find` swallows `NotFound` and returns `nil`; every other error
> propagates.

## Thread safety

A `Client` (and its underlying connection) is **not** safe to share across
threads or fibers concurrently. Use one `Client` per thread/fiber, or guard
access with your own mutex.

## Development

```sh
bundle install     # install dependencies
bin/rspec          # run the test suite (uses VCR cassettes, no live server needed)
bin/rubocop        # lint
bin/guard          # watch files and re-run specs on change
```

Read-only integration specs can be run against a real Icinga2 server (they are
excluded from the default run):

```sh
ICINGA_INTEGRATION=1 \
ICINGA_API_URL=https://icinga.example.net:5665 \
ICINGA_API_USER=root ICINGA_API_PASSWORD=secret \
bin/rspec spec/integration
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
