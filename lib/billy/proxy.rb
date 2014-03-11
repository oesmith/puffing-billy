require 'cgi'
require 'uri'
require 'eventmachine'
require 'billy/request_handler'

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
      'localhost'
    end

    def port
      Socket.unpack_sockaddr_in(EM.get_sockname(@signature)).first
    end

    def cache
      Billy::Cache.instance
    end

    #def call(method, url, headers, body)
    #  stub = find_stub(method, url)
    #  unless stub.nil?
    #    query_string = URI.parse(url).query || ""
    #    params = CGI.parse(query_string)
    #    stub.call(params, headers, body)
    #  end
    #end

    #def stub(url, options = {})
    #  ret = ProxyRequestStub.new(url, options)
    #  @stubs.unshift ret
    #  ret
    #end

    #def reset
    #  @stubs = []
    #end

    #def reset_cache
    #  @cache.reset
    #end

    #def restore_cache
    #  warn "[DEPRECATION] `restore_cache` is deprecated as cache files are dynamically checked. Use `reset_cache` if you just want to clear the cache."
    #  @cache.reset
    #end

    protected

    #def find_stub(method, url)
    #  @stubs.find {|stub| stub.matches?(method, url) }
    #end

    def main_loop
      EM.run do
        EM.error_handler do |e|
          puts e.class.name, e
          puts e.backtrace.join("\n")
        end

        @signature = EM.start_server('127.0.0.1', 0, ProxyConnection) do |p|
          p.handler = request_handler
        end

        Billy.log(:info, "puffing-billy: Proxy listening on #{url}")
      end
    end
  end
end
