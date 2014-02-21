require 'billy/handlers/handler'

module Billy
  class CacheHandler
    extend Forwardable
    include Handler

    # TODO: Does this really need to be static?
    def self.cache
      @@cache ||= Billy::Cache.new
    end

    def handle_request(method, url, headers, body)
      method = method.downcase
      unless handles_request?(method, url, headers, body)
        if (response = cache.fetch(method, url, body))
          Billy.log(:info, "puffing-billy: CACHE #{method} for '#{url}'")
          return response
        end
      end
      nil
    end

    def handles_request?(method, url, headers, body)
      CacheHandler.cache.cached?(method, url, body)
    end

    # Reset the cache to the default state
    def reset
      CacheHandler.cache.reset
    end

    private

    def self.cache=(v)
      @@cache = v
    end

    def cache
      CacheHandler.cache
    end

    def cache=(v)
      CacheHandler.cache = v
    end
  end
end
