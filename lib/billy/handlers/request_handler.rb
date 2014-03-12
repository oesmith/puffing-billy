module Billy
  class RequestHandler
    extend Forwardable
    include Handler

    def_delegators :stub_handler, :stub

    def handlers
      @handlers ||= { :stubs => StubHandler.new,
                      :cache => CacheHandler.new,
                      :proxy => ProxyHandler.new }
    end

    def handle_request(method, url, headers, body)
      # Process the handlers by order of importance
      [:stubs, :cache, :proxy].each do |key|
        if (response = handlers[key].handle_request(method, url, headers, body))
          return response
        end
      end

      body_msg = method == 'post' ? " with body '#{body}'" : ''
      { :error => "puffing-billy: Connection to #{url}#{body_msg} not cached and new http connections are disabled" }
    end

    def handles_request?(method, url, headers, body)
      [:stubs, :cache, :proxy].each do |key|
        return true if handlers[key].handles_request?(method, url, headers, body)
      end

      false
    end

    def reset
      handlers.each_value do |handler|
        handler.reset
      end
    end

    def reset_stubs
      handlers[:stub].reset
    end

    def reset_cache
      handlers[:cache].reset
    end

    private

    def stub_handler
      handlers[:stubs]
    end
  end
end
