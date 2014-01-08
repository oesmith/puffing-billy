require 'uri'
require 'eventmachine'
require 'http/parser'
require 'em-http'
require 'evma_httpserver'

module Billy
  class ProxyConnection < EventMachine::Connection
    attr_accessor :handler
    attr_accessor :cache

    def post_init
      @parser = Http::Parser.new(self)
      @header_data = ""
    end

    def receive_data(data)
      @header_data << data if @headers.nil?
      begin
        @parser << data
      rescue HTTP::Parser::Error
        if @parser.http_method == 'CONNECT'
          # work-around for CONNECT requests until https://github.com/tmm1/http_parser.rb/pull/15 gets merged
          if @header_data.end_with?("\r\n\r\n")
            restart_with_ssl(@header_data.split("\r\n").first.split(/\s+/)[1])
          end
        else
          close_connection
        end
      end
    end

    def on_message_begin
      @headers = nil
      @body = ''
    end

    def on_headers_complete(headers)
      @headers = headers
    end

    def on_body(chunk)
      @body << chunk
    end

    def on_message_complete
      if @parser.http_method == 'CONNECT'
        restart_with_ssl(@parser.request_url)
      else
        if @ssl
          @url = "https://#{@ssl}#{@parser.request_url}"
        else
          @url = @parser.request_url
        end
        handle_request
      end
    end

    protected

    def restart_with_ssl(url)
      @ssl = url
      @parser = Http::Parser.new(self)
      send_data("HTTP/1.0 200 Connection established\r\nProxy-agent: Puffing-Billy/0.0.0\r\n\r\n")
      start_tls(
        :private_key_file => File.expand_path('../mitm.key', __FILE__),
        :cert_chain_file => File.expand_path('../mitm.crt', __FILE__)
      )
    end

    def handle_request
      if handler && handler.respond_to?(:call)
        result = handler.call(@parser.http_method, @url, @headers, @body)
      end

      if result
        Billy.log(:info, "puffing-billy: STUB #{@parser.http_method} #{@url}")
        stub_request(result)
      elsif cache.cached?(@parser.http_method.downcase, @url, @body)
        Billy.log(:info, "puffing-billy: CACHE #{@parser.http_method} #{@url}")
        respond_from_cache
      elsif !disabled_request?
        Billy.log(:info, "puffing-billy: PROXY #{@parser.http_method} #{@url}")
        proxy_request
      else
        close_connection
        body_msg = @parser.http_method == 'post' ? " with body '#{@body}'" : ''
        raise "puffing-billy: Connection to #{@url}#{body_msg} not cached and new http connections are disabled"
      end
    end

    def stub_request(result)
      response = EM::DelegatedHttpResponse.new(self)
      response.status  = result[0]
      response.headers = result[1].merge('Connection' => 'close')
      response.content = result[2]
      response.send_response
    end

    def disabled_request?
      url = URI(@url)
      # In isolated environments, you may want to stop the request from happening
      # or else you get "getaddrinfo: Name or service not known" errors
      if Billy.config.non_whitelisted_requests_disabled
        Helpers.blacklisted_path?(url.path) || !Helpers.whitelisted_url?(url)
      end
    end

    def handle_unsuccessful_response(url, status)
      error_level   = Billy.config.non_successful_error_level
      error_message = "puffing-billy: Received response status code #{status} for #{Helpers.format_url(url)}"
      case error_level
      when :error
        close_connection
        raise error_message
      else
        Billy.log(error_level, error_message)
      end
    end

    def proxy_request
      headers = Hash[@headers.map { |k,v| [k.downcase, v] }]
      headers.delete('accept-encoding')

      req = EventMachine::HttpRequest.new(@url)
      req_opts = {
        :redirects => 0,
        :keepalive => false,
        :head => headers,
        :ssl => { :verify => false }
      }
      req_opts[:body] = @body if @body

      req = req.send(@parser.http_method.downcase, req_opts)

      req.errback do
        Billy.log(:error, "puffing-billy: Request failed: #{@url}")
        close_connection
      end

      req.callback do
        res_status = req.response_header.status
        res_headers = req.response_header.raw
        res_headers = res_headers.merge('Connection' => 'close')
        res_headers.delete('Transfer-Encoding')
        res_content = req.response.force_encoding('BINARY')

        handle_unsuccessful_response(@url, res_status) if !Helpers.successful_status?(res_status)

        if cache.cacheable?(@url, res_headers, res_status)
          cache.store(@parser.http_method.downcase, @url, @body, res_status, res_headers, res_content)
        end

        res = EM::DelegatedHttpResponse.new(self)
        res.status = res_status
        res.headers = res_headers
        res.content = res_content
        res.send_response
      end
    end

    def respond_from_cache
      cached_res = cache.fetch(@parser.http_method.downcase, @url, @body)
      res = EM::DelegatedHttpResponse.new(self)
      res.status = cached_res[:status]
      res.headers = cached_res[:headers]
      res.content = cached_res[:content]
      res.send_response
    end
  end
end
