require 'spec_helper'

describe Billy::ProxyHandler do
  subject { Billy::ProxyHandler.new }
  let(:request) do
    {
      method:   'post',
      url:      'http://example.test:8080/index?some=param',
      headers:  { 'Accept-Encoding'  => 'gzip',
                  'Cache-Control'    => 'no-cache' },
      body:     'Some body'
    }
  end

  describe '#handles_request?' do
    context 'with non-whitelisted requests enabled' do
      before do
        expect(Billy.config).to receive(:non_whitelisted_requests_disabled).and_return(false)
      end

      it 'handles all requests' do
        expect(subject.handles_request?(request[:method],
                                        request[:url],
                                        request[:headers],
                                        request[:body])).to be true
      end
    end
    context 'with non-whitelisted requests disabled' do
      before do
        expect(Billy.config).to receive(:non_whitelisted_requests_disabled).and_return(true)
      end

      it 'does not handle requests that are not white or black listed' do
        expect(subject.handles_request?(request[:method],
                                        request[:url],
                                        request[:headers],
                                        request[:body])).to be false
      end

      context 'a whitelisted host' do
        context 'with a blacklisted path' do
          before do
            expect(Billy.config).to receive(:path_blacklist) { ['/index'] }
          end

          it 'does not handle requests for blacklisted paths' do
            expect(subject.handles_request?(request[:method],
                                            'http://example.test:8080/index?some=param',
                                            request[:headers],
                                            request[:body])).to be false
          end
        end

        context 'as a regex' do
          before do
            expect(Billy.config).to receive(:whitelist) { [%r{example\.test\/a}] }
          end

          it 'handles requests for the host without a port' do
            expect(subject.handles_request?(request[:method],
                                            'http://example.test/a',
                                            request[:headers],
                                            request[:body])).to be_true
          end

          it 'handles requests for the host with a port' do
            expect(subject.handles_request?(request[:method],
                                            'http://example.test:8080/a',
                                            request[:headers],
                                            request[:body])).to be_true
          end
        end

        context 'without a port' do
          before do
            expect(Billy.config).to receive(:whitelist) { ['example.test'] }
          end

          it 'handles requests for the host without a port' do
            expect(subject.handles_request?(request[:method],
                                            'http://example.test',
                                            request[:headers],
                                            request[:body])).to be true
          end

          it 'handles requests for the host with a port' do
            expect(subject.handles_request?(request[:method],
                                            'http://example.test:8080',
                                            request[:headers],
                                            request[:body])).to be true
          end
        end

        context 'with a port' do
          before do
            expect(Billy.config).to receive(:whitelist) { ['example.test:8080'] }
          end

          it 'does not handle requests whitelisted for a specific port' do
            expect(subject.handles_request?(request[:method],
                                            'http://example.test',
                                            request[:headers],
                                            request[:body])).to be false
          end

          it 'handles requests for the host with a port' do
            expect(subject.handles_request?(request[:method],
                                            'http://example.test:8080',
                                            request[:headers],
                                            request[:body])).to be true
          end
        end
      end
    end
  end

  describe '#handle_request' do
    it 'returns nil if it does not handle the request' do
      expect(subject).to receive(:handles_request?).and_return(false)
      expect(subject.handle_request(request[:method],
                                    request[:url],
                                    request[:headers],
                                    request[:body])).to be nil
    end

    context 'with a handled request' do
      let(:response_header) do
        header = Struct.new(:status, :raw).new
        header.status = 200
        header.raw = {}
        header
      end

      let(:em_response)     { double('response') }
      let(:em_request)      do
        double('EM::HttpRequest', error: nil, response: em_response, response_header: response_header)
      end

      before do
        allow(subject).to receive(:handles_request?).and_return(true)
        allow(em_response).to receive(:force_encoding).and_return('The response body')
        allow(EventMachine::HttpRequest).to receive(:new).and_return(em_request)
        expect(em_request).to receive(:post).and_return(em_request)
      end

      it 'returns any error in the response' do
        allow(em_request).to receive(:error).and_return('ERROR!')
        expect(subject.handle_request(request[:method],
                                      request[:url],
                                      request[:headers],
                                      request[:body])).to eql(error: "Request to #{request[:url]} failed with error: ERROR!")
      end

      it 'returns a hashed response if the request succeeds' do
        expect(subject.handle_request(request[:method],
                                      request[:url],
                                      request[:headers],
                                      request[:body])).to eql(status: 200, headers: { 'Connection' => 'close' }, content: 'The response body')
      end

      it 'returns nil if both the error and response are for some reason nil' do
        allow(em_request).to receive(:response).and_return(nil)
        expect(subject.handle_request(request[:method],
                                      request[:url],
                                      request[:headers],
                                      request[:body])).to be nil
      end

      it 'caches the response if cacheable' do
        expect(subject).to receive(:allowed_response_code?).and_return(true)
        expect(Billy::Cache.instance).to receive(:store)
        subject.handle_request(request[:method],
                               request[:url],
                               request[:headers],
                               request[:body])
      end

      it 'uses the timeouts defined in configuration' do
        allow(Billy.config).to receive(:proxied_request_inactivity_timeout).and_return(42)
        allow(Billy.config).to receive(:proxied_request_connect_timeout).and_return(24)

        expect(EventMachine::HttpRequest).to receive(:new).with(request[:url],
                                                                inactivity_timeout: 42,
                                                                connect_timeout: 24
        )

        subject.handle_request(request[:method],
                               request[:url],
                               request[:headers],
                               request[:body])
      end
    end
  end
end
