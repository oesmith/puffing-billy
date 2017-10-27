require 'billy/version'
require 'billy/config'
require 'billy/handlers/handler'
require 'billy/handlers/request_handler'
require 'billy/handlers/stub_handler'
require 'billy/handlers/proxy_handler'
require 'billy/handlers/cache_handler'
require 'billy/proxy_request_stub'
require 'billy/cache'
require 'billy/proxy'
require 'billy/proxy_connection'
require 'billy/railtie' if defined?(Rails)

module Billy
  def self.proxy
    @billy_proxy ||= (
      proxy = Billy::Proxy.new
      proxy.start
      proxy
    )
  end
end
