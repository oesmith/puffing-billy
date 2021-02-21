module Billy
  class HarLog
    attr_reader :har

    def initialize
      define_har
    end

    def define_har
      @har = {
          log: {
              version: '1.1',
              creator: { name: 'Puffing Billy' },
              pages: [{
                startedDateTime: Time.now.strftime('%FT%T.%3N%z'),
                id: 'proxy.har',
                title: 'proxy.har',
                pageTimings: { onContentLoad: -1, onLoad: -1 }
              }],
              entries: []
          }
        }
    end

    def reset
      define_har
    end

    def record(em_request)
      return unless Billy.config.record_proxy_as_har
      entry = em_request.to_s
      @har[:log][:entries].push(entry)
    end
  end
end
