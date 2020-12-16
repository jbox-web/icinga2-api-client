require 'json'
require 'rest-client'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/numeric/time'

require 'icinga2/api/version'

module Icinga2
  module API
    autoload :Interface, 'icinga2/api/interface'
    autoload :Client,    'icinga2/api/client'
    autoload :Service,   'icinga2/api/service'
    autoload :Services,  'icinga2/api/services'
    autoload :Host,      'icinga2/api/host'
    autoload :Hosts,     'icinga2/api/hosts'
    autoload :Resource,  'icinga2/api/resource'
    autoload :Downtime,  'icinga2/api/downtime'
  end
end
