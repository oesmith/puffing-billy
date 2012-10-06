require 'eventmachine'

module Billy
  class Proxy
    def start
      Thread.new do
        EM.run do
          EM.error_handler do |e|
            puts e.class.name, e
            puts e.backtrace.join("\n")
          end

          @signature = EM.start_server('127.0.0.1', 0, ProxyConnection) do |p|
            p.handler = self
          end
        end
      end
      sleep(0.01) while @signature.nil?
    end

    def url
      "http://localhost:#{port}"
    end

    def port
      Socket.unpack_sockaddr_in(EM.get_sockname(@signature)).first
    end

    def call(method, url, headers, body)
      nil
    end
  end
end
