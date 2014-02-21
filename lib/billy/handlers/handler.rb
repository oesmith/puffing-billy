module Billy
  module Handler
    ##
    #
    # Handles an incoming HTTP request and returns a response.
    #
    # This method accepts HTTP request parameters and must return
    # a response hash containing the keys :status, :headers,
    # and :content, or nil if the request cannot be fulfilled.
    #
    # @param  [String] http_method  The HTTP method used, e.g. 'http' or 'https'
    # @param  [String] url          The URL requested.
    # @param  [String] headers      The headers of the HTTP request.
    # @param  [String] body         The body of the HTTP request.
    # @return [Hash]                A hash with the keys [:status, :headers, :content]
    #                               Returns {:error => "Some error message"} if a failure occurs.
    #                               Returns nil if the request cannot be fulfilled.
    def handle_request(http_method, url, headers, body)
      { error: 'The handler has not overridden the handle_request method!' }
    end

    ##
    #
    # Checks if the Handler can respond to the given request.
    #
    # @param  [String] http_method  The HTTP method used, e.g. 'http' or 'https'
    # @param  [String] url          The URL requested.
    # @param  [String] headers      The headers of the HTTP request.
    # @param  [String] body         The body of the HTTP request.
    # @return [Boolean]             True if the Handler can respond to the request, else false.
    #
    def handles_request?(http_method, url, headers, body)
      false
    end

    ##
    #
    # Resets the Handler to the default/new state
    #
    # This allows the handler to be set back to its default state
    # at the end of tests or whenever else necessary.
    #
    def reset; end
  end
end