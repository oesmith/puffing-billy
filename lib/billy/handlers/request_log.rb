module Billy
  class RequestLog
    attr_reader :requests, :har

    def initialize
      @requests = []
      if Billy.config.record_proxy_as_har
        @requests = {
          log: {
              version: '1.1',
              creator: { name: 'Puffing Billy' },
              pages: [{
                startedDateTime: Time.now.strftime('%FT%T.%3N%z'),
                id: 'proxy.har',
                title: 'proxy.har',
                pageTimings: { onContentLoad: -1, onLoad: -1 }
              }],
              entries: []
          }
        }
    end

    def reset
      @requests = []
    end

    def record(method, url, headers, body)
      return unless Billy.config.record_requests

      if Billy.config.record_proxy_as_har
        entry = {abc: 5}
        require 'pry'; binding.pry
        @requests[:log][:entries].push(entry)
      else
        request = {
          status: :inflight,
          handler: nil,
          method: method,
          url: url,
          headers: headers,
          body: body
        }
        @requests.push(request)
      end

      request
    end

    def complete(request, handler)
      return unless Billy.config.record_requests

      request.merge! status: :complete,
                     handler: handler
    end
  end
end
