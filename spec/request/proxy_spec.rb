require 'spec_helper'
require 'puffing-billy'

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
    http.head('/echo').headers['http_x_echoserver'].should == 'HEAD /echo'
  end

  it 'should proxy DELETE requests' do
    http.delete('/echo').body.should == 'DELETE /echo'
  end
end

shared_examples_for 'a request stub' do
  it 'should stub GET requests' do
    @proxy.stub("#{url}/foo").
      and_return(200, {}, 'hello, GET!')
    http.get('/foo').body.should == 'hello, GET!'
  end

  it 'should stub POST requests' do
    @proxy.stub("#{url}/bar", :method => :post).
      and_return(200, {}, 'hello, POST!')
    http.post('/bar', :foo => :bar).body.should == 'hello, POST!'
  end

  it 'should stub PUT requests' do
    @proxy.stub("#{url}/baz", :method => :put).
      and_return(200, {}, 'hello, PUT!')
    http.put('/baz', :foo => :bar).body.should == 'hello, PUT!'
  end

  it 'should stub HEAD requests' do
    @proxy.stub("#{url}/bap", :method => :head).
      and_return(200, {'HTTP-X-Hello' => 'hello, HEAD!'}, nil)
    http.head('/bap').headers['http_x_hello'] == 'hello, HEAD!'
  end

  it 'should stub DELETE requests' do
    @proxy.stub("#{url}/bam", :method => :delete).
      and_return(200, {}, 'hello, DELETE!')
    http.delete('/bam').body.should == 'hello, DELETE!'
  end
end

describe Billy::Proxy do

  before :all do
    @proxy = Billy::Proxy.new
    @proxy.start
  end

  before do
    @http = Faraday.new @http_url,
      :proxy => { :uri => @proxy.url },
      :keepalive => false,
      :timeout => 0.5
    @https = Faraday.new @https_url,
      :ssl => { :verify => false },
      :proxy => { :uri => @proxy.url },
      :keepalive => false,
      :timeout => 0.5
  end

  after do
    @proxy.reset
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

end
