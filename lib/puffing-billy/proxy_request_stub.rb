module Billy
  class ProxyRequestStub
    attr_accessor :url, :method
    def initialize(url, options = {})
      @options = {:method => :get}.merge(options)
      @method = @options[:method]
      @url = url
      @response = [204, {}, ""]
    end

    def and_return(*response)
      @response = response
      self
    end

    def call(headers, body)
      @response
    end

    def method
      @options[:method]
    end
  end
end
