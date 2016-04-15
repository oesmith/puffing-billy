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
      it 'returns stubbed responses' do
        expect(stub_handler).to receive(:handle_request).with(*args).and_return('foo')
        expect(cache_handler).to_not receive(:handle_request)
        expect(proxy_handler).to_not receive(:handle_request)
        expect(subject.handle_request(*args)).to eql 'foo'
      end

      it 'returns cached responses' do
        expect(stub_handler).to receive(:handle_request).with(*args)
        expect(cache_handler).to receive(:handle_request).with(*args).and_return('bar')
        expect(proxy_handler).to_not receive(:handle_request)
        expect(subject.handle_request(*args)).to eql 'bar'
      end

      it 'returns proxied responses' do
        expect(stub_handler).to receive(:handle_request).with(*args)
        expect(cache_handler).to receive(:handle_request).with(*args)
        expect(proxy_handler).to receive(:handle_request).with(*args).and_return('baz')
        expect(subject.handle_request(*args)).to eql 'baz'
      end

      it 'returns an error hash if request is not handled' do
        expect(stub_handler).to receive(:handle_request).with(*args)
        expect(cache_handler).to receive(:handle_request).with(*args)
        expect(proxy_handler).to receive(:handle_request).with(*args)
        expect(subject.handle_request(*args)).to eql(error: 'Connection to url not cached and new http connections are disabled')
      end

      it 'returns an error hash with body message if request cached based on body is not handled' do
        args[0] = Billy.config.cache_request_body_methods[0]
        expect(stub_handler).to receive(:handle_request).with(*args)
        expect(cache_handler).to receive(:handle_request).with(*args)
        expect(proxy_handler).to receive(:handle_request).with(*args)
        expect(subject.handle_request(*args)).to eql(error: "Connection to url with body 'body' not cached and new http connections are disabled")
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
