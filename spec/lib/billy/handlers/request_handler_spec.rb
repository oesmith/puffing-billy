require 'spec_helper'

describe Billy::RequestHandler do
  subject { Billy::RequestHandler.new }

  it 'implements Handler' do
    expect(subject).to be_a Billy::Handler
  end

  describe '#handlers' do
    it 'has a stub handler' do
      expect(subject.handlers[:stubs]).to be_a Billy::StubHandler
    end

    it 'has a cache handler' do
      expect(subject.handlers[:cache]).to be_a Billy::CacheHandler
    end

    it 'has a proxy handler' do
      expect(subject.handlers[:proxy]).to be_a Billy::ProxyHandler
    end
  end

  context 'with stubbed handlers' do
    let(:args) { %w(get url headers body) }
    let(:stub_handler) { double('StubHandler') }
    let(:cache_handler) { double('CacheHandler') }
    let(:proxy_handler) { double('ProxyHandler') }
    let(:handlers) do
      {
        stubs: stub_handler,
        cache: cache_handler,
        proxy: proxy_handler
      }
    end

    before do
      allow(subject).to receive(:handlers).and_return(handlers)
    end

    describe '#handles_request?' do
      it 'returns false if no handlers handle the request' do
        handlers.each do |_key, handler|
          expect(handler).to receive(:handles_request?).with(*args).and_return(false)
        end
        expect(subject.handles_request?(*args)).to be false
      end

      it 'returns true immediately if the stub handler handles the request' do
        expect(stub_handler).to receive(:handles_request?).with(*args).and_return(true)
        expect(cache_handler).to_not receive(:handles_request?)
        expect(proxy_handler).to_not receive(:handles_request?)
        expect(subject.handles_request?(*args)).to be true
      end

      it 'returns true if the cache handler handles the request' do
        expect(stub_handler).to receive(:handles_request?).with(*args).and_return(false)
        expect(cache_handler).to receive(:handles_request?).with(*args).and_return(true)
        expect(proxy_handler).to_not receive(:handles_request?)
        expect(subject.handles_request?(*args)).to be true
      end

      it 'returns true if the proxy handler handles the request' do
        expect(stub_handler).to receive(:handles_request?).with(*args).and_return(false)
        expect(cache_handler).to receive(:handles_request?).with(*args).and_return(false)
        expect(proxy_handler).to receive(:handles_request?).with(*args).and_return(true)
        expect(subject.handles_request?(*args)).to be true
      end
    end

    describe '#handle_request' do
      before do
        allow(Billy::config).to receive(:record_requests).and_return(true)
      end

      it 'returns stubbed responses' do
        expect(stub_handler).to receive(:handle_request).with(*args).and_return('foo')
        expect(cache_handler).to_not receive(:handle_request)
        expect(proxy_handler).to_not receive(:handle_request)
        expect(subject.handle_request(*args)).to eql 'foo'
        expect(subject.requests).to eql([{status: :complete, handler: :stubs, method: 'get', url: 'url', headers: 'headers', body: 'body'}])
      end

      it 'returns cached responses' do
        expect(stub_handler).to receive(:handle_request).with(*args)
        expect(cache_handler).to receive(:handle_request).with(*args).and_return('bar')
        expect(proxy_handler).to_not receive(:handle_request)
        expect(subject.handle_request(*args)).to eql 'bar'
        expect(subject.requests).to eql([{status: :complete, handler: :cache, method: 'get', url: 'url', headers: 'headers', body: 'body'}])
      end

      it 'returns proxied responses' do
        expect(stub_handler).to receive(:handle_request).with(*args)
        expect(cache_handler).to receive(:handle_request).with(*args)
        expect(proxy_handler).to receive(:handle_request).with(*args).and_return('baz')
        expect(subject.handle_request(*args)).to eql 'baz'
        expect(subject.requests).to eql([{status: :complete, handler: :proxy, method: 'get', url: 'url', headers: 'headers', body: 'body'}])
      end

      it 'returns an error hash if request is not handled' do
        expect(stub_handler).to receive(:handle_request).with(*args)
        expect(cache_handler).to receive(:handle_request).with(*args)
        expect(proxy_handler).to receive(:handle_request).with(*args)
        expect(subject.handle_request(*args)).to eql(error: 'Connection to url not cached and new http connections are disabled')
        expect(subject.requests).to eql([{status: :complete, handler: :error, method: 'get', url: 'url', headers: 'headers', body: 'body'}])
      end

      it 'returns an error hash with body message if request cached based on body is not handled' do
        args[0] = Billy.config.cache_request_body_methods[0]
        expect(stub_handler).to receive(:handle_request).with(*args)
        expect(cache_handler).to receive(:handle_request).with(*args)
        expect(proxy_handler).to receive(:handle_request).with(*args)
        expect(subject.handle_request(*args)).to eql(error: "Connection to url with body 'body' not cached and new http connections are disabled")
        expect(subject.requests).to eql([{status: :complete, handler: :error, method: 'post', url: 'url', headers: 'headers', body: 'body'}])
      end

      it 'returns an error hash on unhandled exceptions' do
        # Allow handling requests initially
        allow(stub_handler).to receive(:handle_request)
        allow(cache_handler).to receive(:handle_request)

        allow(proxy_handler).to receive(:handle_request).and_raise("Any Proxy Error")
        expect(subject.handle_request(*args)).to eql(error: "Any Proxy Error")

        allow(cache_handler).to receive(:handle_request).and_raise("Any Cache Error")
        expect(subject.handle_request(*args)).to eql(error: "Any Cache Error")

        allow(stub_handler).to receive(:handle_request).and_raise("Any Stub Error")
        expect(subject.handle_request(*args)).to eql(error: "Any Stub Error")
      end

      context 'before_handle_request activated' do
        before do
          handle_request = proc { |method, url, headers, body|
            [method, url, headers, "#{body}_modified"]
          }
          allow(Billy::config).to receive(:before_handle_request).and_return(handle_request)
        end

        after do
          allow(Billy::config).to receive(:before_handle_request).and_call_original
        end

        it 'modify request before handling' do
          new_args = %w(get url headers body_modified)
          expect(stub_handler).to receive(:handle_request).with(*new_args)
          expect(cache_handler).to receive(:handle_request).with(*new_args).and_return('bar')
          expect(proxy_handler).to_not receive(:handle_request)
          expect(subject.handle_request(*args)).to eql 'bar'
          expect(subject.requests).to eql([{status: :complete, handler: :cache, method: 'get', url: 'url', headers: 'headers', body: 'body'}])
        end
      end
    end

    describe '#stubs' do
      it 'delegates to the stub_handler' do
        expect(stub_handler).to receive(:stubs)
        subject.stubs
      end
    end

    describe '#stub' do
      it 'delegates to the stub_handler' do
        expect(stub_handler).to receive(:stub).with('some args')
        subject.stub('some args')
      end
    end

    describe '#reset' do
      it 'resets all of the handlers' do
        handlers.each do |_key, handler|
          expect(handler).to receive(:reset)
        end
        expect(subject.request_log).to receive(:reset)
        subject.reset
      end
    end

    describe '#reset_stubs' do
      it 'resets the stub handler' do
        expect(stub_handler).to receive(:reset)
        subject.reset_stubs
      end
    end

    describe '#reset_cache' do
      it 'resets the cache handler' do
        expect(cache_handler).to receive(:reset)
        subject.reset_cache
      end
    end

    describe '#restore_cache' do
      it 'resets the cache handler' do
        expect(cache_handler).to receive(:reset)
        subject.reset_cache
      end
    end
  end
end
