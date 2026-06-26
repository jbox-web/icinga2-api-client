# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- `#acknowledge` and `#remove_acknowledgement` on both `Host` and `Service`
  (`acknowledge-problem` / `remove-acknowledgement` actions).
- `Host#schedule_downtime` and `Host#downtimes` (host-level downtimes), mirroring
  the service-level API.
- `Service#schedule_downtime` / `Host#schedule_downtime` now return the created
  `Downtime` object instead of the raw API payload.
- `Icinga2::API::Error` hierarchy (`NotFound`, `ClientError`, `ServerError`,
  `Timeout`, `ConnectionFailed`); Faraday transport errors are translated into
  it so callers no longer depend on Faraday's exceptions.
- `Error#response` exposes the underlying Faraday response (status/body) when
  available.
- Configurable `open_timeout` / `timeout` connection options (`timeout`
  defaults to 30 seconds).
- `Service#schedule_downtime` validates required parameters and raises
  `ArgumentError` when any is missing.
- Client/connection options are validated: an unknown option (e.g. a typo
  like `verify_ssl` instead of `ssl_options`) now raises `ArgumentError`
  instead of being silently ignored.
- Read-only live integration specs (`spec/integration/`, opt-in via
  `ICINGA_INTEGRATION=1`).
- Gemspec metadata (source code, changelog, bug tracker URIs).

### Fixed
- `Resource#to_h(only:/except:)` no longer mutates the object's attributes.
- Downtimes returned by `host.services.downtimes` are now correctly associated
  with their `Service` (was always `nil`).
- `Hosts#find` returns `nil` instead of crashing on an empty result set, and
  `Hosts#all` skips entries that have no `attrs`.
- `Resource` attribute access no longer collides with real method names.
- `Services`/`Service` no longer cache `all`/`downtimes`, so repeated calls
  reflect the current server state.
- `Interface` tolerates empty or malformed response bodies (returns `[]`).
- `Downtime#cancel` raises instead of silently returning `nil` when nothing was
  cancelled.
- `Downtime` no longer fabricates `1970` timestamps when they are absent.

### Changed
- `faraday` constrained to `~> 2.0` and `zeitwerk` to `~> 2.6`.
- Test suite runs with VCR `record: :none` (never contacts a live server).
