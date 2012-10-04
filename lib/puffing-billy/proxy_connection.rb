require 'eventmachine'
require 'http/parser'

module Billy
  class ProxyConnection < EventMachine::Connection
    attr_accessor :proxy

    def post_init
      puts 'post_init'
      @parser = Http::Parser.new(self)
      @data = ""
    end

    def receive_data(data)
      puts 'receive_data'
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
      puts 'on_message_begin'
      @headers = nil
      @body = ''
    end

    def on_headers_complete(headers)
      puts 'on_headers_complete'
      @headers = headers
    end

    def on_body(chunk)
      puts 'on_body'
      @body << chunk
    end

    def on_message_complete
      puts 'on_message_complete'
      p [@parser.http_method, @headers, @body]
      # TODO :)
    end
  end
end
