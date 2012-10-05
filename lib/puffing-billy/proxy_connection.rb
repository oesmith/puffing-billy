require 'eventmachine'
require 'http/parser'
require 'em-http'
require 'evma_httpserver'

module Billy
  class ProxyConnection < EventMachine::Connection
    attr_accessor :proxy

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
          restart_with_ssl(@header_data.split("\r\n").first.split(/\s+/)[1])
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
          url = "https://#{@ssl}#{@parser.request_url}"
        else
          url = @parser.request_url
        end
        puts "#{@parser.http_method} #{url}"
        handle_request(url)
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

    def handle_request(url)
      proxy_request(url)
    end

    def proxy_request(url)
      headers = Hash[@headers.map { |k,v| [k.downcase, v] }].merge('connection' => 'close')
      req = EventMachine::HttpRequest.new(url)
      req_opts = {
        :redirects => 0,
        :keepalive => false,
        :head => headers,
      }
      req_opts[:body] = @body if @body
      req = req.send(@parser.http_method.downcase, req_opts)

      req.errback do
        puts "Request failed: #{url}"
        close_connection
      end

      req.callback do
        res = EM::DelegatedHttpResponse.new(self)
        res.status = req.response_header.status
        res.headers = req.response_header
        res.content = req.response
        res.send_response
      end
    end

  end
end
