require 'spec_helper'
require 'timeout'

describe 'intercept request example', type: :feature, js: true do
  before do
    Billy.config.record_stub_requests = true
  end

  it 'should intercept a GET request directly' do
    stub = proxy.stub('http://example.com/')
    visit 'http://example.com/'
    expect(stub.has_requests?).to be true
    expect(stub.requests).not_to be_empty
  end

  it 'should intercept a POST request through an intermediary page' do
    stub = proxy.stub('http://example.com/', method: 'post')
    visit '/intercept_request.html'
    Timeout::timeout(5) do
      sleep(0.1) until stub.has_requests?
    end
    request = stub.requests.shift
    expect(request[:body]).to eql 'foo=bar'
  end
end
