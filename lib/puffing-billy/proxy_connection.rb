require 'eventmachine'
require 'http/parser'
require 'uri'

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
      top = [
        @parser.http_method,
        path,
        "HTTP/#{@parser.http_version.join('.')}"
      ].join(' ')
      headers = [top] + @headers.map { |k,v| "#{k}: #{v}" }
      puts headers.join("\r\n") + "\r\n\r\n"
    end

    private

    def path
      uri = URI(@parser.request_url)
      ret = uri.path || '/'
      ret << "?#{uri.query}" unless uri.query.nil?
      ret
    end
  end
end
