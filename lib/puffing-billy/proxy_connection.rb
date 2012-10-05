require 'eventmachine'
require 'http/parser'
require 'em-http'
require 'evma_httpserver'

module Billy
  class ProxyConnection < EventMachine::Connection
    attr_accessor :proxy

    def post_init
      @parser = Http::Parser.new(self)
      @data = ""
    end

    def receive_data(data)
      @data << data
      unless @is_connect
        begin
          @parser << data
        rescue HTTP::Parser::Error
          if @parser.http_method == 'CONNECT'
            @is_connect = true
          end
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
      req = EventMachine::HttpRequest.new(@parser.request_url)
      req = req.send(@parser.http_method.downcase, {
        :redirects => 0,
        :keepalive => false,
        :head => headers,
        #:body => @body
      })

      req.errback do
        puts "Request failed: #{@parser.request_url}"
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
