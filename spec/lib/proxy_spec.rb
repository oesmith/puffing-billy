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
    before do
      Billy.config.whitelist = []
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

  context 'ignore_params GET requests' do
    before do
      Billy.config.ignore_params = ['/analytics']
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

  context "cache persistence" do
    let(:cached_file) do
      f = proxy.cache.key('get',"#{url}/foo","") + ".yml"
      File.join(Billy.config.cache_path, f)
    end

    before { Billy.config.whitelist = [] }

    after do
      File.delete(cached_file) if File.exists?(cached_file)
    end

    context "enabled" do
      before { Billy.config.persist_cache = true }

      it 'should persist' do
        r = http.get('/foo')
        File.exists?(cached_file).should be_true
      end

      it 'should be read initially from persistent cache' do
        File.open(cached_file, 'w') do |f|
          cached = {
            :headers => {},
            :content => "GET /foo cached"
          }
          f.write(cached.to_yaml(:Encoding => :Utf8))
        end

        r = http.get('/foo')
        r.body.should == 'GET /foo cached'
      end
    end

    context "disabled" do
      before { Billy.config.persist_cache = false }

      it 'shouldnt persist' do
        r = http.get('/foo')
        File.exists?(cached_file).should be_false
      end
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

    it 'defaults to nil scope' do
      expect(proxy.cache.scope).to be_nil
    end

    context 'HTTP' do
      let!(:url) { @http_url }
      let!(:http) { @http }
      it_should_behave_like 'a cache'
    end

    context 'HTTPS' do
      let!(:url) { @https_url }
      let!(:http) { @https }
      it_should_behave_like 'a cache'
    end

    context 'with a cache scope' do
      let!(:url)  { @http_url }
      let!(:http) { @http }

      before do
        proxy.cache.scope_to "my_cache"
      end

      after do
        proxy.cache.use_default_scope
      end

      it_should_behave_like 'a cache'

      it 'uses the cache scope' do
        expect(proxy.cache.scope).to eq("my_cache")
      end

      it 'can be reset to the default scope' do
        proxy.cache.use_default_scope
        expect(proxy.cache.scope).to be_nil
      end

      it 'can execute a block against a cache scope' do
        expect(proxy.cache.scope).to eq "my_cache"
        proxy.cache.with_scope "another_cache" do
          expect(proxy.cache.scope).to eq "another_cache"
        end
        expect(proxy.cache.scope).to eq "my_cache"
      end

      it 'requires a block to be passed to with_scope' do
        expect {proxy.cache.with_scope "some_scope"}.to raise_error ArgumentError
      end

      it 'should have different keys for the same request under a different scope' do
        args = ['get',"#{url}/foo",""]
        key = proxy.cache.key(*args)
        proxy.cache.with_scope "another_cache" do
          expect(proxy.cache.key(*args)).to_not eq key
        end
      end
    end
  end
end
