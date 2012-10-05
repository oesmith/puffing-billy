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
          @ssl = @header_data.split("\r\n").first.split(/\s+/)[1]
          @parser = Http::Parser.new(self)
          send_data("HTTP/1.0 200 Connection established\r\nProxy-agent: Puffing-Billy/0.0.0\r\n\r\n")
          start_tls(:private_key_file => 'node/mitm.key', :cert_chain_file => 'node/mitm.crt')
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
      headers = Hash[@headers.map { |k,v| [k.downcase, v] }].merge('connection' => 'close')
      if @ssl
        url = "https://#{@ssl}#{@parser.request_url}"
      else
        url = @parser.request_url
      end
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
