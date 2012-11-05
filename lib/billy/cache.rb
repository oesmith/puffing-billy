require 'resolv'
require 'uri'

module Billy
  class Cache
    def initialize
      reset
    end

    def cacheable?(url, headers)
      if Billy.config.cache
        host = URI(url).host
        Billy.log(:info, Billy.config.whitelist)
        !Billy.config.whitelist.include?(host)
        # TODO test headers for cacheability
      end
    end

    def cached?(url)
      !@cache[url].nil?
    end

    def fetch(url)
      @cache[url]
    end

    def store(url, status, headers, content)
      @cache[url] = {
        :status => status,
        :headers => headers,
        :content => content
      }
    end

    def reset
      @cache = {}
    end
  end
end
