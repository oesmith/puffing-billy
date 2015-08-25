require 'cgi'
require 'eventmachine'

module Billy
  class Proxy
    extend Forwardable
    attr_reader :request_handler

    def_delegators :request_handler, :stub, :reset, :reset_cache, :restore_cache, :handle_request

    def initialize
      @request_handler = Billy::RequestHandler.new
      reset
    end

    def start(threaded = true)
      if threaded
        Thread.new { main_loop }
        sleep(0.01) while @signature.nil?
      else
        main_loop
      end
    end

    def url
      "http://#{host}:#{port}"
    end

    def host
      Billy.config.proxy_host
    end

    def port
      Socket.unpack_sockaddr_in(EM.get_sockname(@signature)).first
    end

    def cache
      Billy::Cache.instance
    end

    protected

    def main_loop
      EM.run do
        EM.error_handler do |e|
          Billy.log :error, "#{e.class} (#{e.message}):"
          Billy.log :error, e.backtrace.join("\n")
        end

        @signature = EM.start_server('127.0.0.1', Billy.config.proxy_port, ProxyConnection) do |p|
          p.handler = request_handler
          p.cache = @cache
        end

        Billy.log(:info, "puffing-billy: Proxy listening on #{url}")
      end
    end
  end
end
