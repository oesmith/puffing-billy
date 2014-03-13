require 'spec_helper'

describe Billy::CacheHandler do
  let!(:handler) { Billy::CacheHandler.new }
  let(:request) { {
      method:   'post',
      url:      'http://example.test:8080/index?some=param',
      headers:  {'Accept-Encoding'  => 'gzip',
                 'Cache-Control'    => 'no-cache' },
      body:     'Some body'
  } }

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
      expect(handler.cached?(nil,nil,nil)).to be_true
    end
    it 'does not handle the request if it is not cached' do
      expect(Billy::Cache.instance).to receive(:cached?).and_return(false)
      expect(handler.cached?(nil,nil,nil)).to be_false
    end
  end

  describe '#handle_request' do
    it 'returns nil if the request cannot be handled' do
      expect(Billy::Cache.instance).to receive(:cached?).and_return(false)
      expect(handler.handle_request(request[:method],
                                    request[:url],
                                    request[:headers],
                                    request[:body])).to be_nil
    end
    it 'returns a cached response if the request can be handled' do
      expect(Billy::Cache.instance).to receive(:cached?).and_return(true)
      expect(Billy::Cache.instance).to receive(:fetch).and_return({:status=>200, :headers=>{"Connection"=>"close"}, :content=>"The response body"})
      expect(handler.handle_request(request[:method],
                                    request[:url],
                                    request[:headers],
                                    request[:body])).to eql({:status=>200, :headers=>{"Connection"=>"close"}, :content=>"The response body"})
    end
    it 'returns nil if the Cache fails to handle the response for some reason' do
      expect(Billy::Cache.instance).to receive(:cached?).and_return(true)
      expect(Billy::Cache.instance).to receive(:fetch).and_return(nil)
      expect(handler.handle_request(request[:method],
                                    request[:url],
                                    request[:headers],
                                    request[:body])).to be_nil
    end
  end
end
