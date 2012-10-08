module Billy
  class ProxyRequestStub
    def initialize(url, options = {})
      @options = {:method => :get}.merge(options)
      @method = @options[:method].to_s.upcase
      @url = url
      @response = [204, {}, ""]
    end

    def and_return(*response)
      @response = response
      self
    end

    def call(*args)
      if @response.first.respond_to?(:call)
        @response.first.call(*args)
      else
        @response
      end
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
