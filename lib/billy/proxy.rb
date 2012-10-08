require 'eventmachine'

module Billy
  class Proxy
    def initialize
      reset
    end

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
      stub = @stubs[stub_key(method, url)]
      unless stub.nil?
        stub.call(headers, body)
      end
    end

    def stub(url, options = {})
      ret = ProxyRequestStub.new(url, options)
      @stubs[stub_key(ret.method, ret.url)] = ret
    end

    def reset
      @stubs = {}
    end

    protected

    def stub_key(method, url)
      "#{method.to_s.upcase} #{url}"
    end
  end
end
