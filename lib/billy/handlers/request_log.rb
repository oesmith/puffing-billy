module Billy
  class RequestLog
    attr_reader :requests

    def initialize
      @requests = []
    end

    def reset
      @requests = []
    end

    def record(method, url, headers, body, cache_scope)
      Billy.log(:info, "puffing-billy: REQUEST LOG: #{method} #{url}")
      purl = url.match(/.*staging\.hirefrederick.com\:443(.*)/)
      puts "REQUEST LOG: #{cache_scope} #{method} #{purl.captures[0]}" if purl
      return unless Billy.config.record_requests

      request = {
        scope: cache_scope,
        cache_key: nil,
        status: :inflight,
        handler: nil,
        method: method,
        url: url,
        headers: headers,
        body: body
      }
      @requests.push(request)

      request
    end

    def complete(request, handler, cache_key)
      return unless Billy.config.record_requests

      request.merge! status: :complete,
                     handler: handler,
                     cache_key: cache_key
    end
  end
end
