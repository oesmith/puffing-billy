require 'spec_helper'
require 'billy'
require 'resolv'

shared_examples_for 'a proxy server' do
  it 'should proxy GET requests' do
    http.get('/echo').body.should == 'GET /echo'
  end

  it 'should proxy POST requests' do
    http.post('/echo', :foo => 'bar').body.should == "POST /echo\nfoo=bar"
  end

  it 'should proxy PUT requests' do
    http.post('/echo', :foo => 'bar').body.should == "POST /echo\nfoo=bar"
  end

  it 'should proxy HEAD requests' do
    http.head('/echo').headers['HTTP-X-EchoServer'].should == 'HEAD /echo'
  end

  it 'should proxy DELETE requests' do
    http.delete('/echo').body.should == 'DELETE /echo'
  end
end

shared_examples_for 'a request stub' do
  it 'should stub GET requests' do
    proxy.stub("#{url}/foo").
      and_return(:text => 'hello, GET!')
    http.get('/foo').body.should == 'hello, GET!'
  end

  it 'should stub POST requests' do
    proxy.stub("#{url}/bar", :method => :post).
      and_return(:text => 'hello, POST!')
    http.post('/bar', :foo => :bar).body.should == 'hello, POST!'
  end

  it 'should stub PUT requests' do
    proxy.stub("#{url}/baz", :method => :put).
      and_return(:text => 'hello, PUT!')
    http.put('/baz', :foo => :bar).body.should == 'hello, PUT!'
  end

  it 'should stub HEAD requests' do
    proxy.stub("#{url}/bap", :method => :head).
      and_return(:headers => {'HTTP-X-Hello' => 'hello, HEAD!'})
    http.head('/bap').headers['http_x_hello'] == 'hello, HEAD!'
  end

  it 'should stub DELETE requests' do
    proxy.stub("#{url}/bam", :method => :delete).
      and_return(:text => 'hello, DELETE!')
    http.delete('/bam').body.should == 'hello, DELETE!'
  end
end

shared_examples_for 'a cache' do

  context 'whitelisted GET requests' do
    it 'should not be cached' do
      r = http.get('/foo')
      r.body.should == 'GET /foo'
      expect {
        expect {
          r = http.get('/foo')
        }.to change { r.headers['HTTP-X-EchoCount'].to_i }.by(1)
      }.to_not change { r.body }
    end
  end

  context 'other GET requests' do
    around do |example|
      Billy.configure { |c| c.whitelist = [] }
      example.run
      Billy.configure { |c| c.whitelist = Billy::Config::DEFAULT_WHITELIST }
    end

    it 'should be cached' do
      r = http.get('/foo')
      r.body.should == 'GET /foo'
      expect {
        expect {
          r = http.get('/foo')
        }.to_not change { r.headers['HTTP-X-EchoCount'] }
      }.to_not change { r.body }
    end
  end

  context 'ignore_parms GET requests' do
    around do |example|
      Billy.configure { |c| c.ignore_params = ['/analytics'] }
      example.run
      Billy.configure { |c| c.ignore_params = [] }
    end

    it 'should be cached' do
      r = http.get('/analytics?some_param=5')
      r.body.should == 'GET /analytics'
      expect {
        expect {
          r = http.get('/analytics?some_param=20')
        }.to change { r.headers['HTTP-X-EchoCount'].to_i }.by(1)
      }.to_not change { r.body }
    end
  end
end

describe Billy::Proxy do

  before do
    @http = Faraday.new @http_url,
      :proxy => { :uri => proxy.url },
      :keepalive => false,
      :timeout => 0.5
    @https = Faraday.new @https_url,
      :ssl => { :verify => false },
      :proxy => { :uri => proxy.url },
      :keepalive => false,
      :timeout => 0.5
  end

  context 'proxying' do

    context 'HTTP' do
      let!(:http) { @http }
      it_should_behave_like 'a proxy server'
    end

    context 'HTTPS' do
      let!(:http) { @https }
      it_should_behave_like 'a proxy server'
    end

  end

  context 'stubbing' do

    context 'HTTP' do
      let!(:url) { @http_url }
      let!(:http) { @http }
      it_should_behave_like 'a request stub'
    end

    context 'HTTPS' do
      let!(:url) { @https_url }
      let!(:http) { @https }
      it_should_behave_like 'a request stub'
    end

  end

  context 'caching' do

    context 'HTTP' do
      let!(:http) { @http }
      it_should_behave_like 'a cache'
    end

    context 'HTTPS' do
      let!(:http) { @https }
      it_should_behave_like 'a cache'
    end

  end

end
