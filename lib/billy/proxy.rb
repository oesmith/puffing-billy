require 'cgi'
require 'eventmachine'
require 'timeout'

module Billy
  class Proxy
    extend Forwardable
    attr_reader :request_handler

    def_delegators :request_handler, :stub, :stubs, :unstub, :reset, :reset_cache, :restore_cache, :requests, :handle_request

    def initialize
      @request_handler = Billy::RequestHandler.new
      reset
    end

    def start(threaded = true)
      if threaded
        Thread.new { main_loop }
        sleep(0.01) while (not defined?(@signature)) || @signature.nil?
      else
        main_loop
      end
    end

    def stop
      return if @signature.nil?

      server_port = port
      EM.stop
      wait_for_server_shutdown! server_port
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

    def wait_for_server_shutdown!(server_port)
      Timeout::timeout(60) do
        sleep(0.01) while port_in_use? server_port
      end
    rescue Timeout::Error
      Billy.log(:error, "puffing-billy: Event machine not shutdown correctly on port #{port}")
    end

    def port_in_use?(port)
      s = TCPSocket.new(host, port)
      s.close
      Billy.log(:info, "puffing-billy: Waiting for event machine to shutdown on port #{port}")
      s
    rescue Errno::ECONNREFUSED, Errno::EADDRNOTAVAIL, Errno::ENETUNREACH, Errno::ECONNRESET
      false
    end

    def main_loop
      EM.run do
        EM.error_handler do |e|
          Billy.log :error, "#{e.class} (#{e.message}):"
          Billy.log :error, e.backtrace.join("\n") unless e.backtrace.nil?
        end

        @signature = EM.start_server(host, Billy.config.proxy_port, ProxyConnection) do |p|
          p.handler = request_handler
          p.cache = @cache if defined?(@cache)
          p.errback do |msg|
            Billy.log :error, msg
          end
        end

        Billy.log(:info, "puffing-billy: Proxy listening on #{url}")
      end
    end
  end
end
