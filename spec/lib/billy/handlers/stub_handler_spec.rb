require 'spec_helper'

describe Billy::StubHandler do
  let(:handler) { Billy::StubHandler.new }
  let(:request) { {
      method:   'GET',
      url:      'http://example.test:8080/index?some=param',
      headers:  {'Accept-Encoding'  => 'gzip',
                 'Cache-Control'    => 'no-cache' },
      body:     'Some body'
  } }

  describe '#handles_request?' do
    it 'handles the request if it is stubbed' do
      expect(handler).to receive(:find_stub).and_return("a stub")
      expect(handler.handles_request?(nil,nil,nil,nil)).to be_true
    end
    it 'does not handle the request if it is not stubbed' do
      expect(handler).to receive(:find_stub).and_return(nil)
      expect(handler.handles_request?(nil,nil,nil,nil)).to be_false
    end
  end

  describe '#handle_request' do
    it 'returns nil if the request is not stubbed' do
      expect(handler).to receive(:handles_request?).and_return(false)
      expect(handler.handle_request(nil,nil,nil,nil)).to be_nil
    end
    it 'returns a response hash if the request is stubbed' do
      stub = double("stub", :call => [200, {'Content-Type' => 'application/json'}, "Some content"])
      expect(handler).to receive(:handles_request?).and_return(true)
      expect(handler).to receive(:find_stub).and_return(stub)
      expect(handler.handle_request('GET',
                                    request[:url],
                                    request[:headers],
                                    request[:body])).to eql({:status => 200,
                                                             :headers => {'Content-Type' => 'application/json'},
                                                             :content => "Some content"})
    end
  end

  describe '#reset' do
    before do
      # Can't use request params when creating the stub.
      # See https://github.com/oesmith/puffing-billy/issues/21
      handler.stub('http://example.test:8080/index')
    end

    it 'resets the stubs' do
      expect(handler.handles_request?('GET',
                                      request[:url],
                                      request[:headers],
                                      request[:body])).to be_true
      handler.reset
      expect(handler.handles_request?('GET',
                                      request[:url],
                                      request[:headers],
                                      request[:body])).to be_false
    end
  end

  it '#stubs requests' do
    handler.stub('http://example.test:8080/index')
    expect(handler.handles_request?('GET',
                                    request[:url],
                                    request[:headers],
                                    request[:body])).to be_true
  end
end
