require 'cgi'
require 'uri'
require 'eventmachine'

module Billy
  class Proxy
    attr_reader :cache

    def initialize
      reset
      @cache = Billy::Cache.new
      caches << @cache
    end

    def caches
      @caches ||= []
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

    def call(method, url, headers, body)
      stub = find_stub(method, url)
      unless stub.nil?
        query_string = URI.parse(url).query || ""
        params = CGI.parse(query_string)
        stub.call(params, headers, body)
      end
    end

    def stub(url, options = {})
      ret = ProxyRequestStub.new(url, options)
      @stubs.unshift ret
      ret
    end

    def reset
      @stubs = []
    end

    def use_default_cache
      @cache = caches[0]
    end

    def use_cache_named(name = nil)
      # This could be done without the caches array using a new Cache with the given name
      #   to run the block against, but if a specific named cache is used multiple times it
      #   would need to rescan the cache directory every time it is accessed/used to
      #   run a block, which would result in a potentially significant performance hit.
      cache_index = caches.index { |cache| cache.name == name }
      cache_index ||= (caches << Billy::Cache.new(name)).length - 1
      @cache = caches[cache_index]
    end

    def with_cache_named(name = nil, &block)
      original_cache = @cache
      use_cache_named(name)
      block.call()
    ensure
      @cache = original_cache
    end

    def nuke_all_caches
      reset_all_caches
      @cache = Billy::Cache.new
      @caches = []
      caches << @cache
    end

    def reset_all_caches
      caches.each { |c| c.reset }
    end

    def reset_cache
      @cache.reset
    end

    def restore_cache
      @cache.reset
      @cache.load_dir
    end

    protected

    def find_stub(method, url)
      @stubs.find {|stub| stub.matches?(method, url) }
    end

    def main_loop
      EM.run do
        EM.error_handler do |e|
          puts e.class.name, e
          puts e.backtrace.join("\n")
        end

        @signature = EM.start_server('127.0.0.1', 0, ProxyConnection) do |p|
          p.handler = self
          p.cache = @cache
        end

        Billy.log(:info, "Proxy listening on #{url}")
      end
    end

    private

    attr_writer :caches
  end
end
