require 'billy/handlers/handler'
require 'addressable/uri'
require 'cgi'

module Billy
  class CacheHandler
    extend Forwardable
    include Handler

    attr_reader :cache

    def_delegators :cache, :reset, :cached?

    def initialize
      @cache = Billy::Cache.instance
    end

    def handle_request(method, url, headers, body)
      method = method.downcase
      if handles_request?(method, url, headers, body)
        if (response = cache.fetch(method, url, body))
          Billy.log(:info, "puffing-billy: CACHE #{method} for '#{url}'")

          if Billy.config.dynamic_jsonp
            replace_response_callback(response, url)
          end

          if Billy.config.after_cache_handles_request
            request = { method: method, url: url, headers: headers, body: body }
            Billy.config.after_cache_handles_request.call(request, response)
          end

          return response
        end
      end
      nil
    end

    def handles_request?(method, url, _headers, body)
      cached?(method, url, body)
    end

    private

    def replace_response_callback(response, url)
      request_uri = Addressable::URI.parse(url)
      if request_uri.query
        params = CGI.parse(request_uri.query)
        if params['callback'].any? && response[:content].match(/\w+\(/)
          response[:content].sub!(/\w+\(/, params['callback'].first + '(')
        end
      end
    end
  end
end
