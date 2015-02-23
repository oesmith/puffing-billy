require 'spec_helper'

describe Billy::CacheHandler do
  let(:handler) { Billy::CacheHandler.new }
  let(:request) do
    {
      method:   'post',
      url:      'http://example.test:8080/index?some=param&callback=dynamicCallback5678',
      headers:  { 'Accept-Encoding'  => 'gzip',
                  'Cache-Control'    => 'no-cache' },
      body:     'Some body'
    }
  end

  it 'delegates #reset to the cache' do
    expect(Billy::Cache.instance).to receive(:reset).at_least(:once)
    handler.reset
  end

  it 'delegates #cached? to the cache' do
    expect(Billy::Cache.instance).to receive :cached?
    handler.cached?
  end

  describe '#handles_request?' do
    it 'handles the request if it is cached' do
      expect(Billy::Cache.instance).to receive(:cached?).and_return(true)
      expect(handler.handles_request?(nil, nil, nil, nil)).to be true
    end

    it 'does not handle the request if it is not cached' do
      expect(Billy::Cache.instance).to receive(:cached?).and_return(false)
      expect(handler.handles_request?(nil, nil, nil, nil)).to be false
    end
  end

  describe '#handle_request' do
    it 'returns nil if the request cannot be handled' do
      expect(Billy::Cache.instance).to receive(:cached?).and_return(false)
      expect(handler.handle_request(request[:method],
                                    request[:url],
                                    request[:headers],
                                    request[:body])).to be nil
    end

    it 'returns a cached response if the request can be handled' do
      expect(Billy::Cache.instance).to receive(:cached?).and_return(true)
      expect(Billy::Cache.instance).to receive(:fetch).and_return(status: 200, headers: { 'Connection' => 'close' }, content: 'The response body')
      expect(handler.handle_request(request[:method],
                                    request[:url],
                                    request[:headers],
                                    request[:body])).to eql(status: 200, headers: { 'Connection' => 'close' }, content: 'The response body')
    end

    context 'updating jsonp callback names enabled' do
      before do
        Billy.config.dynamic_jsonp = true
      end

      it 'updates the cached response if the callback is dynamic' do
        expect(Billy::Cache.instance).to receive(:cached?).and_return(true)
        expect(Billy::Cache.instance).to receive(:fetch).and_return(status: 200, headers: { 'Connection' => 'close' }, content: 'dynamicCallback1234({"yolo":"kitten"})')
        expect(handler.handle_request(request[:method],
                                      request[:url],
                                      request[:headers],
                                      request[:body])).to eql(status: 200, headers: { 'Connection' => 'close' }, content: 'dynamicCallback5678({"yolo":"kitten"})')
      end

      it 'is flexible about the format of the response body' do
        expect(Billy::Cache.instance).to receive(:cached?).and_return(true)
        expect(Billy::Cache.instance).to receive(:fetch).and_return(status: 200, headers: { 'Connection' => 'close' }, content: "/**/ dynamicCallback1234(\n{\"yolo\":\"kitten\"})")
        expect(handler.handle_request(request[:method],
                                      request[:url],
                                      request[:headers],
                                      request[:body])).to eql(status: 200, headers: { 'Connection' => 'close' }, content: "/**/ dynamicCallback5678(\n{\"yolo\":\"kitten\"})")
      end

      it 'does not interfere with non-jsonp requests' do
        jsonp_request = request
        other_request = {
          method:  'get',
          url:     'http://example.test:8080/index?hanukkah=latkes',
          headers: { 'Accept-Encoding' => 'gzip', 'Cache-Control' => 'no-cache' },
          body:    'no jsonp'
        }

        allow(Billy::Cache.instance).to receive(:cached?).and_return(true)
        allow(Billy::Cache.instance).to receive(:fetch).with(jsonp_request[:method], jsonp_request[:url], jsonp_request[:body]).and_return(status: 200,
                                                                                                                                           headers: { 'Connection' => 'close' },
                                                                                                                                           content: 'dynamicCallback1234({"yolo":"kitten"})')
        allow(Billy::Cache.instance).to receive(:fetch).with(other_request[:method], other_request[:url], other_request[:body]).and_return(status: 200,
                                                                                                                                           headers: { 'Connection' => 'close' },
                                                                                                                                           content: 'no jsonp but has parentheses()')

        expect(handler.handle_request(other_request[:method],
                                      other_request[:url],
                                      other_request[:headers],
                                      other_request[:body])).to eql(status: 200, headers: { 'Connection' => 'close' }, content: 'no jsonp but has parentheses()')
      end
    end

    context 'updating jsonp callback names disabled' do
      before do
        Billy.config.dynamic_jsonp = false
      end

      it 'does not change the response' do
        expect(Billy::Cache.instance).to receive(:cached?).and_return(true)
        expect(Billy::Cache.instance).to receive(:fetch).and_return(status: 200, headers: { 'Connection' => 'close' }, content: 'dynamicCallback1234({"yolo":"kitten"})')
        expect(handler.handle_request(request[:method],
                                      request[:url],
                                      request[:headers],
                                      request[:body])).to eql(status: 200, headers: { 'Connection' => 'close' }, content: 'dynamicCallback1234({"yolo":"kitten"})')
      end
    end

    it 'returns nil if the Cache fails to handle the response for some reason' do
      expect(Billy::Cache.instance).to receive(:cached?).and_return(true)
      expect(Billy::Cache.instance).to receive(:fetch).and_return(nil)
      expect(handler.handle_request(request[:method],
                                    request[:url],
                                    request[:headers],
                                    request[:body])).to be nil
    end
  end
end
