require 'billy/version'
require 'billy/config'
require 'billy/handlers/handler'
require 'billy/handlers/request_handler'
require 'billy/handlers/request_log'
require 'billy/handlers/stub_handler'
require 'billy/handlers/proxy_handler'
require 'billy/handlers/har_log'
require 'billy/handlers/cache_handler'
require 'billy/proxy_request_stub'
require 'billy/cache'
require 'billy/ssl/certificate_helpers'
require 'billy/ssl/authority'
require 'billy/ssl/certificate'
require 'billy/ssl/certificate_chain'
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

  def self.certificate_authority
    @certificate_authority ||= Billy::Authority.new
  end

  # This global shortcut can be used inside of request stubs. You can modify
  # the request beforehand and/or modify the actual response which is passed
  # back by this method. But you can also implement a custom proxy passing
  # method if you like to. This is just a shortcut.
  def self.pass_request(params, headers, body, url, method)
      handler = proxy.request_handler.handlers[:proxy]
      response = handler.handle_request(method, url, headers, body)
      {
        code: response[:status],
        body: response[:content],
        headers: response[:headers]
      }
  end
end
