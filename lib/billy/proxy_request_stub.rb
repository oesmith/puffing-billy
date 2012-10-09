require 'yajl'

module Billy
  class ProxyRequestStub
    def initialize(url, options = {})
      @options = {:method => :get}.merge(options)
      @method = @options[:method].to_s.upcase
      @url = url
      @response = [204, {}, ""]
    end

    def and_return(response)
      @response = response
      self
    end

    def call(params, headers, body)
      if @response.respond_to?(:call)
        res = @response.call(params, headers, body)
      else
        res = @response
      end

      code = res[:code] || 200

      headers = res[:headers] || {}
      headers['Content-Type'] = res[:content_type] if res[:content_type]

      if res[:json]
        headers = {'Content-Type' => 'application/json'}.merge(headers)
        body = [Yajl::Encoder.encode(res[:json])]
      elsif res[:jsonp]
        headers = {'Content-Type' => 'application/javascript'}.merge(headers)
        if res[:callback]
          callback = res[:callback]
        elsif res[:callback_param]
          callback = params[res[:callback_param]][0]
        else
          callback = params['callback'][0]
        end
        body = ["#{callback}(#{Yajl::Encoder::encode(res[:jsonp])})"]
      elsif res[:text]
        headers = {'Content-Type' => 'text/plain'}.merge(headers)
        body = [res[:text]]
      elsif res[:redirect_to]
        code = 302
        headers = {'Location' => res[:redirect_to]}
      else
        body = [res[:body]]
      end

      [code, headers, body]
    end

    def matches?(method, url)
      if method == @method
        if @url.is_a?(Regexp)
          url.match(@url)
        else
          url == @url
        end
      end
    end
  end
end
