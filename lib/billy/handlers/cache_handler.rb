require 'billy/handlers/handler'

module Billy
  class CacheHandler
    extend Forwardable
    include Handler

    def_delegators :cache, :reset, :cached?

    def initialize
      @cache = Billy::Cache.instance
    end

    def handle_request(method, url, headers, body)
      method = method.downcase
      if handles_request?(method, url, headers, body)
        if (response = cache.fetch(method, url, body))
          Billy.log(:info, "puffing-billy: CACHE #{method} for '#{url}'")
          return response
        end
      end
      nil
    end

    def handles_request?(method, url, headers, body)
      cached?(method, url, body)
    end

    private

    def cache
      @cache
    end
  end
end
