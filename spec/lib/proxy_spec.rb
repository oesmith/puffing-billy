require 'spec_helper'
require 'billy'
require 'resolv'

shared_examples_for 'a proxy server' do
  it 'should proxy GET requests' do
    expect(http.get('/echo').body).to eql 'GET /echo'
  end

  it 'should proxy POST requests' do
    expect(http.post('/echo', foo: 'bar').body).to eql "POST /echo\nfoo=bar"
  end

  it 'should proxy PUT requests' do
    expect(http.post('/echo', foo: 'bar').body).to eql "POST /echo\nfoo=bar"
  end

  it 'should proxy HEAD requests' do
    expect(http.head('/echo').headers['HTTP-X-EchoServer']).to eql 'HEAD /echo'
  end

  it 'should proxy DELETE requests' do
    expect(http.delete('/echo').body).to eql 'DELETE /echo'
  end
end

shared_examples_for 'a request stub' do
  it 'should stub GET requests' do
    proxy.stub("#{url}/foo")
      .and_return(text: 'hello, GET!')
    expect(http.get('/foo').body).to eql 'hello, GET!'
  end

  it 'should stub GET response statuses' do
    proxy.stub("#{url}/foo")
      .and_return(code: 200)
    expect(http.get('/foo').status).to eql 200
  end

  it 'should stub POST requests' do
    proxy.stub("#{url}/bar", method: :post)
      .and_return(text: 'hello, POST!')
    expect(http.post('/bar', foo: :bar).body).to eql 'hello, POST!'
  end

  it 'should stub PUT requests' do
    proxy.stub("#{url}/baz", method: :put)
      .and_return(text: 'hello, PUT!')
    expect(http.put('/baz', foo: :bar).body).to eql 'hello, PUT!'
  end

  it 'should stub HEAD requests' do
    proxy.stub("#{url}/bap", method: :head)
      .and_return(headers: { 'HTTP-X-Hello' => 'hello, HEAD!' })
    expect(http.head('/bap').headers['http-x-hello']).to eql 'hello, HEAD!'
  end

  it 'should stub DELETE requests' do
    proxy.stub("#{url}/bam", method: :delete)
      .and_return(text: 'hello, DELETE!')
    expect(http.delete('/bam').body).to eql 'hello, DELETE!'
  end
end

shared_examples_for 'a cache' do
  context 'whitelisted GET requests' do
    it 'should not be cached' do
      assert_noncached_url
    end

    context 'with ports' do
      before do
        rack_app_url = URI(http.url_prefix)
        Billy.config.whitelist = ["#{rack_app_url.host}:#{rack_app_url.port}"]
      end

      it 'should not be cached ' do
        assert_noncached_url
      end
    end
  end

  context 'non-whitelisted GET requests' do
    before do
      Billy.config.whitelist = []
    end

    it 'should be cached' do
      assert_cached_url
    end

    context 'with ports' do
      before do
        rack_app_url = URI(http.url_prefix)
        Billy.config.whitelist = ["#{rack_app_url.host}:#{rack_app_url.port + 1}"]
      end

      it 'should be cached' do
        assert_cached_url
      end
    end
  end

  context 'ignore_params GET requests' do
    before do
      Billy.config.ignore_params = ['/analytics']
    end

    it 'should be cached' do
      r = http.get('/analytics?some_param=5')
      expect(r.body).to eql 'GET /analytics'
      expect do
        expect do
          r = http.get('/analytics?some_param=20')
        end.to change { r.headers['HTTP-X-EchoCount'].to_i }.by(1)
      end.to_not change { r.body }
    end
  end

  context 'path_blacklist GET requests' do
    before do
      Billy.config.path_blacklist = ['/api']
    end

    it 'should be cached' do
      assert_cached_url('/api')
    end
  end

  context 'cache persistence' do
    let(:cache_path) { Billy.config.cache_path }
    let(:cached_key) { proxy.cache.key('get', "#{url}/foo", '') }
    let(:cached_file) do
      f = cached_key + '.yml'
      File.join(cache_path, f)
    end

    before do
      Billy.config.whitelist = []
      Dir.mkdir(cache_path) unless Dir.exist?(cache_path)
    end

    after do
      File.delete(cached_file) if File.exist?(cached_file)
    end

    context 'enabled' do
      before { Billy.config.persist_cache = true }

      it 'should persist' do
        r = http.get('/foo')
        expect(File.exist?(cached_file)).to be true
      end

      it 'should be read initially from persistent cache' do
        File.open(cached_file, 'w') do |f|
          cached = {
            headers: {},
            content: 'GET /foo cached'
          }
          f.write(cached.to_yaml(Encoding: :Utf8))
        end

        r = http.get('/foo')
        expect(r.body).to eql 'GET /foo cached'
      end

      context 'cache_request_headers requests' do
        it 'should not be cached by default' do
          r = http.get('/foo')
          saved_cache = Billy.proxy.cache.fetch_from_persistence(cached_key)
          expect(saved_cache.keys).not_to include :request_headers
        end

        context 'when enabled' do
          before do
            Billy.config.cache_request_headers = true
          end

          it 'should be cached' do
            r = http.get('/foo')
            saved_cache = Billy.proxy.cache.fetch_from_persistence(cached_key)
            expect(saved_cache.keys).to include :request_headers
          end
        end
      end

      context 'ignore_cache_port requests' do
        it 'should be cached without port' do
          r   = http.get('/foo')
          url = URI(r.env[:url])
          saved_cache = Billy.proxy.cache.fetch_from_persistence(cached_key)

          expect(saved_cache[:url]).to_not eql(url.to_s)
          expect(saved_cache[:url]).to eql(url.to_s.gsub(":#{url.port}", ''))
        end
      end

      context 'non_whitelisted_requests_disabled requests' do
        before { Billy.config.non_whitelisted_requests_disabled = true }

        it 'should raise error when disabled' do
          # TODO: Suppress stderr output: https://gist.github.com/adamstegman/926858
          expect { http.get('/foo') }.to raise_error(Faraday::Error::ConnectionFailed, 'end of file reached')
        end
      end

      context 'non_successful_cache_disabled requests' do
        before do
          rack_app_url = URI(http_error.url_prefix)
          Billy.config.whitelist = ["#{rack_app_url.host}:#{rack_app_url.port}"]
          Billy.config.non_successful_cache_disabled = true
        end

        it 'should not cache non-successful response when enabled' do
          http_error.get('/foo')
          expect(File.exist?(cached_file)).to be false
        end

        it 'should cache successful response when enabled' do
          assert_cached_url
        end
      end

      context 'non_successful_error_level requests' do
        before do
          rack_app_url = URI(http_error.url_prefix)
          Billy.config.whitelist = ["#{rack_app_url.host}:#{rack_app_url.port}"]
          Billy.config.non_successful_error_level = :error
        end

        it 'should raise error for non-successful responses when :error' do
          # When this config setting is set, the EventMachine running the test servers is killed upon error raising
          # The `raise` is required to bubble up the error to the test running it
          # The Faraday error is raised upon `close_connection` so this can be non-pending if we can do one of the following:
          # 1) Remove the `raise error_message` conditionally for this test
          # 2) Restart the test servers if they aren't running
          # 3) Change the test servers to start/stop for each test instead of before all
          # 4) Remove the test server completely and rely on the server instantiated by the app
          pending 'Unable to test this without affecting the running test servers'
          # If the 'pending' continues to execute the spec, 'skip' it to avoid EM errors.
          # If 'pending' stops the test, 'skip' isn't defined but it won't hit this line.
          skip 'Unable to test this without affecting the running test servers'
          expect { http_error.get('/foo') }.to raise_error(Faraday::Error::ConnectionFailed)
        end
      end
    end

    context 'disabled' do
      before { Billy.config.persist_cache = false }

      it 'shouldnt persist' do
        r = http.get('/foo')
        expect(File.exist?(cached_file)).to be false
      end
    end
  end

  def assert_noncached_url(url = '/foo')
    r = http.get(url)
    expect(r.body).to eql "GET #{url}"
    expect do
      expect do
        r = http.get(url)
      end.to change { r.headers['HTTP-X-EchoCount'].to_i }.by(1)
    end.to_not change { r.body }
  end

  def assert_cached_url(url = '/foo')
    r = http.get(url)
    expect(r.body).to eql "GET #{url}"
    expect do
      expect do
        r = http.get(url)
      end.to_not change { r.headers['HTTP-X-EchoCount'] }
    end.to_not change { r.body }
  end
end

describe Billy::Proxy do
  before do
    # Adding non-valid Faraday options throw an error: https://github.com/arsduo/koala/pull/311
    # Valid options: :request, :proxy, :ssl, :builder, :url, :parallel_manager, :params, :headers, :builder_class
    faraday_options = {
      proxy: { uri: proxy.url },
      request: { timeout: 1.0 }
    }

    @http       = Faraday.new @http_url,  faraday_options
    @https      = Faraday.new @https_url, faraday_options.merge(ssl: { verify: false })
    @http_error = Faraday.new @error_url, faraday_options
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
      let!(:url)  { @http_url }
      let!(:http) { @http }
      it_should_behave_like 'a request stub'
    end

    context 'HTTPS' do
      let!(:url)  { @https_url }
      let!(:http) { @https }
      it_should_behave_like 'a request stub'
    end
  end

  context 'caching' do
    it 'defaults to nil scope' do
      expect(proxy.cache.scope).to be nil
    end

    context 'HTTP' do
      let!(:url)        { @http_url }
      let!(:http)       { @http }
      let!(:http_error) { @http_error }
      it_should_behave_like 'a cache'
    end

    context 'HTTPS' do
      let!(:url)        { @https_url }
      let!(:http)       { @https }
      let!(:http_error) { @http_error }
      it_should_behave_like 'a cache'
    end

    context 'with a cache scope' do
      let!(:url)        { @http_url }
      let!(:http)       { @http }
      let!(:http_error) { @http_error }

      before do
        proxy.cache.scope_to 'my_cache'
      end

      after do
        proxy.cache.use_default_scope
      end

      it_should_behave_like 'a cache'

      it 'uses the cache scope' do
        expect(proxy.cache.scope).to eq('my_cache')
      end

      it 'can be reset to the default scope' do
        proxy.cache.use_default_scope
        expect(proxy.cache.scope).to be nil
      end

      it 'can execute a block against a cache scope' do
        expect(proxy.cache.scope).to eq 'my_cache'
        proxy.cache.with_scope 'another_cache' do
          expect(proxy.cache.scope).to eq 'another_cache'
        end
        expect(proxy.cache.scope).to eq 'my_cache'
      end

      it 'requires a block to be passed to with_scope' do
        expect { proxy.cache.with_scope 'some_scope' }.to raise_error ArgumentError
      end

      it 'should have different keys for the same request under a different scope' do
        args = ['get', "#{url}/foo", '']
        key = proxy.cache.key(*args)
        proxy.cache.with_scope 'another_cache' do
          expect(proxy.cache.key(*args)).to_not eq key
        end
      end
    end
  end
end
