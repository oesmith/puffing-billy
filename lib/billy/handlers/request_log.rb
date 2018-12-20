module Billy
  class RequestLog
    attr_reader :requests

    def initialize
      @requests = []
    end

    def reset
      @requests = []
    end

    def record(method, url, headers, body)
      return unless Billy.config.record_requests

      request = {
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

    def complete(request, response, handler)
      return unless Billy.config.record_requests

      request.merge! status: :complete,
                     handler: handler,
                     code: response[:status]
    end
  end
end
