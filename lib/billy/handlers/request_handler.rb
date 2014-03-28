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
      if Billy.config.non_whitelisted_error_level == :error
        return { :error => "Connection to #{url}#{body_msg} not cached and new http connections are disabled" }
      else
        return { :warn => "Connection to #{url}#{body_msg} not cached and new http connections are disabled" }
     end
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
      handlers[:stubs].reset
    end

    def reset_cache
      handlers[:cache].reset
    end

    def restore_cache
      warn "[DEPRECATION] `restore_cache` is deprecated as cache files are dynamically checked. Use `reset_cache` if you just want to clear the cache."
      reset_cache
    end

    private

    def stub_handler
      handlers[:stubs]
    end
  end
end
