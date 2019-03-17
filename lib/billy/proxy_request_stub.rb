require 'multi_json'

module Billy
  class ProxyRequestStub
    attr_reader :requests

    def initialize(url, options = {})
      @options = { method: :get }.merge(options)
      @method = @options[:method].to_s.upcase
      @url = url
      @requests = []
      @response = { code: 204, headers: {}, text: '' }
    end

    def and_return(response)
      @response = response
      self
    end

    def call(method, url, params, headers, body)
      push_request(method, url, params, headers, body)

      if @response.respond_to?(:call)
        res = @response.call(params, headers, body, url, method)
      else
        res = @response
      end

      code = res[:code] || 200

      headers = res[:headers] || {}
      headers['Content-Type'] = res[:content_type] if res[:content_type]

      if res[:json]
        headers = { 'Content-Type' => 'application/json' }.merge(headers)
        body = MultiJson.dump(res[:json])
      elsif res[:jsonp]
        headers = { 'Content-Type' => 'application/javascript' }.merge(headers)
        if res[:callback]
          callback = res[:callback]
        elsif res[:callback_param]
          callback = params[res[:callback_param]][0]
        else
          callback = params['callback'][0]
        end
        body = "#{callback}(#{MultiJson.dump(res[:jsonp])})"
      elsif res[:text]
        headers = { 'Content-Type' => 'text/plain' }.merge(headers)
        body = res[:text]
      elsif res[:redirect_to]
        code = 302
        headers = { 'Location' => res[:redirect_to] }
      else
        body = res[:body]
      end

      [code, headers, body]
    end

    def has_requests?
      @requests.any?
    end

    def matches?(method, url)
      if @method == 'ALL' || method == @method
        if @url.is_a?(Regexp)
          url.match(@url)
        else
          Billy.config.strip_query_params ? (url.split('?')[0] == @url) : (url == @url)
        end
      end
    end

    private

    attr_writer :requests

    def push_request(method, url, params, headers, body)
      if Billy.config.record_stub_requests
        @requests.push({
          method: method,
          url: url,
          params: params,
          headers: headers,
          body: body
        })
      end
    end
  end
end
