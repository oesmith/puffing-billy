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
      f = Billy.proxy.cache.key('get',"#{url}/foo","") + ".yml"
      File.join(Billy.proxy.cache.cache_path, f)
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

    it 'uses an unnamed cache by default' do
      expect(Billy.proxy.cache.name).to be_nil
    end

    it 'matches the Billy config path by default' do
      expect(Billy.proxy.cache.cache_path).to eq Billy.config.cache_path
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

    context 'with a named cache' do
      let!(:url)  { @http_url }
      let!(:http) { @http }

      before do
        Billy.proxy.use_cache_named "my_cache"
      end

      after do

        Billy.proxy.nuke_all_caches
      end

      it_should_behave_like 'a cache'

      it 'uses the named cache' do
        expect(Billy.proxy.cache.name).to eq("my_cache")
      end

      it 'can nuke all caches' do
        Billy.config.whitelist = []
        Billy.config.persist_cache = true
        Billy.proxy.use_cache_named "another_cache"
        Billy.proxy.use_cache_named "my_cache"
        expect(Billy.proxy.cache.name).to eq "my_cache"
        expect(Billy.proxy.caches.size).to eq 3
        http.get('/foo')
        expect(Billy.proxy.cache.cached?('get', "#{url}/foo", "")).to be_true
        Billy.proxy.nuke_all_caches
        expect(Billy.proxy.caches.size).to eq 1
        expect(Billy.proxy.cache.name).to be_nil
        expect(Billy.proxy.cache.cached?('get', "#{url}/foo", "")).to be_false
      end

      it 'can be reset to the default cache' do
        Billy.proxy.use_default_cache
        expect(Billy.proxy.cache.name).to be_nil
      end

      it 'uses the existing named cache if it already exists' do
        c = Billy.proxy.cache
        Billy.proxy.use_cache_named "another_cache"
        Billy.proxy.use_cache_named "my_cache"
        expect(Billy.proxy.cache).to be_equal(c)
      end

      it 'can execute a block against a named cache' do
        expect(Billy.proxy.cache.name).to eq "my_cache"
        Billy.proxy.with_cache_named "another_cache" do
          expect(Billy.proxy.cache.name).to eq "another_cache"
        end
        expect(Billy.proxy.cache.name).to eq "my_cache"
      end
    end

  end

end
