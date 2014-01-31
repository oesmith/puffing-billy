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
        stubbed_response = handler.call(@parser.http_method, @url, @headers, @body)
      end

      if stubbed_response
        Billy.log(:info, "puffing-billy: STUB #{@parser.http_method} for '#{@url}'")
        respond_from_stub(stubbed_response)
      elsif cache.cached?(@parser.http_method.downcase, @url, @body)
        Billy.log(:info, "puffing-billy: CACHE #{@parser.http_method} for '#{@url}'")
        respond_from_cache
      elsif !disabled_request?
        Billy.log(:info, "puffing-billy: PROXY #{@parser.http_method} for '#{@url}'")
        proxy_request
      else
        close_connection
        body_msg = @parser.http_method == 'post' ? " with body '#{@body}'" : ''
        raise "puffing-billy: Connection to #{@url}#{body_msg} not cached and new http connections are disabled"
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

        handle_response_code(res_status)

        if cacheable?(res_headers, res_status)
          cache.store(@parser.http_method.downcase, @url, headers, @body, res_headers, res_status, res_content)
        end

        send_response(res_status,
                      res_headers,
                      res_content)
      end
    end

    def disabled_request?
      url = URI(@url)
      # In isolated environments, you may want to stop the request from happening
      # or else you get "getaddrinfo: Name or service not known" errors
      if Billy.config.non_whitelisted_requests_disabled
        blacklisted_path?(url.path) || !whitelisted_url?(url)
      end
    end

    def handle_response_code(status)
      log_level = successful_status?(status) ? :info : Billy.config.non_successful_error_level
      log_message = "puffing-billy: Received response status code #{status} for #{@url}"
      Billy.log(log_level, log_message)
      if log_level == :error
        close_connection
        raise log_message
      end
    end

    def cacheable?(headers, status)
      if Billy.config.cache
        url = URI(@url)
        # Cache the responses if they aren't whitelisted host[:port]s but always cache blacklisted paths on any hosts
        cacheable_headers?(headers) && cacheable_status?(status) && (!whitelisted_url?(url) || blacklisted_path?(url.path))
      end
    end

 private

    def respond_from_stub(stubbed_response)
      send_response(stubbed_response[0],
                    stubbed_response[1].merge('Connection' => 'close'),
                    stubbed_response[2])
    end

    def respond_from_cache
      cached_res = cache.fetch(@parser.http_method.downcase, @url, @body)
      send_response(cached_res[:status],
                    cached_res[:headers],
                    cached_res[:content])
    end

    def send_response(status, headers, content)
      res = EM::DelegatedHttpResponse.new(self)
      res.status = status
      res.headers = headers
      res.content = content
      res.send_response
    end

    def whitelisted_host?(host)
      Billy.config.whitelist.include?(host)
    end

    def whitelisted_url?(url)
      whitelisted_host?(url.host) || whitelisted_host?("#{url.host}:#{url.port}")
    end

    def blacklisted_path?(path)
      Billy.config.path_blacklist.index{|bl| path.include?(bl)}
    end

    def successful_status?(status)
      (200..299).include?(status) || status == 304
    end

    def cacheable_headers?(headers)
      #TODO: test headers for cacheability (ie. Cache-Control: no-cache)
      true
    end

    def cacheable_status?(status)
      Billy.config.non_successful_cache_disabled ? successful_status?(status) : true
    end

  end
end
