require 'spec_helper'

describe Billy::Cache do
  let(:cache) { Billy::Cache.instance }
  let(:params) { '?foo=bar' }
  let(:callback) { '&callback=quux' }
  let(:fragment) { '#baz' }
  let(:base_url) { 'http://example.com' }
  let(:pipe_url) { 'https://fonts.googleapis.com:443/css?family=Cabin+Sketch:400,700|Love+Ya+Like+A+Sister' }
  let(:fragment_url) { "#{base_url}/#{fragment}" }
  let(:params_url) { "#{base_url}#{params}" }
  let(:params_url_with_callback) { "#{base_url}#{params}#{callback}" }
  let(:params_fragment_url) { "#{base_url}#{params}#{fragment}" }

  describe 'format_url' do
    context 'with ignore_params set to false' do
      it 'is a no-op if there are no params' do
        expect(cache.format_url(base_url)).to eq base_url
      end
      it 'appends params if there are params' do
        expect(cache.format_url(params_url)).to eq params_url
      end
      it 'appends params and fragment if both are present' do
        expect(cache.format_url(params_fragment_url)).to eq params_fragment_url
      end
      it 'does not raise error for URLs with pipes' do
        expect { cache.format_url(pipe_url) }.not_to raise_error
      end

      context 'when dynamic_jsonp is true' do
        it 'omits the callback param by default' do
          expect(cache.format_url(params_url_with_callback, false, true)).to eq params_url
        end

        it 'omits the params listed in Billy.config.dynamic_jsonp_keys' do
          allow(Billy.config).to receive(:dynamic_jsonp_keys) { ['foo'] }

          expect(cache.format_url(params_url_with_callback, false, true)).to eq "#{base_url}?callback=quux"
        end
      end

      it 'retains the callback param is dynamic_jsonp is false' do
        expect(cache.format_url(params_url_with_callback)).to eq params_url_with_callback
      end
    end

    context 'with ignore_params set to true' do
      it 'is a no-op if there are no params' do
        expect(cache.format_url(base_url, true)).to eq base_url
      end
      it 'omits params if there are params' do
        expect(cache.format_url(params_url, true)).to eq base_url
      end
      it 'omits params and fragment if both are present' do
        expect(cache.format_url(params_fragment_url, true)).to eq base_url
      end
    end

    context 'with merge_cached_responses_whitelist set' do
      let(:analytics_url1) { 'http://www.example-analytics.com/user/SDF879932/' }
      let(:analytics_url2) { 'http://www.example-analytics.com/user/OIWEMLW39/' }
      let(:regular_url) { 'http://www.example-analytics.com/user.js' }

      let(:regex_to_match_analytics_urls_only) do
        # Note that it matches the forward slash at the end of the URL, which doesn't match regular_url:
        /www\.example\-analytics\.com\/user\//
      end

      before do
        allow(Billy.config).to receive(:merge_cached_responses_whitelist) {
          [regex_to_match_analytics_urls_only]
        }
      end

      it "has one cache key for the two analytics urls that match, and a separate one for the other that doesn't" do
        expect(cache.key('post', analytics_url1, 'body')).to eq cache.key('post', analytics_url2, 'body')
        expect(cache.key('post', analytics_url1, 'body')).not_to eq cache.key('post', regular_url, 'body')
      end

      it 'More specifically, the cache keys should be identical for the 2 analytics urls' do
        identical_cache_key = 'post_5fcb7a450e4cd54dcffcb526212757ee0ca9dc17'
        distinct_cache_key = 'post_www.example-analytics.com_81f097654a523bd7ddb10fd4aee781723e076a1a_02083f4579e08a612425c0c1a17ee47add783b94'

        expect(cache.key('post', analytics_url1, 'body')).to eq identical_cache_key
        expect(cache.key('post', regular_url, 'body')).to eq distinct_cache_key
        expect(cache.key('post', analytics_url2, 'body')).to eq identical_cache_key
      end
    end

    context 'with cache_request_body_methods set' do
      before do
        allow(Billy.config).to receive(:cache_request_body_methods) {
          ['patch']
        }
      end

      context "for requests with methods specified in cache_request_body_methods" do
        it "should have a different cache key for requests with different bodies" do
          key1 = cache.key('patch', "http://example.com", "body1")
          key2 = cache.key('patch', "http://example.com", "body2")
          expect(key1).not_to eq key2
        end

        it "should have the same cache key for requests with the same bodies" do
          key1 = cache.key('patch', "http://example.com", "body1")
          key2 = cache.key('patch', "http://example.com", "body1")
          expect(key1).to eq key2
        end
      end

      it "should have the same cache key for request with different bodies if their methods are not included in cache_request_body_methods" do
          key1 = cache.key('put', "http://example.com", "body1")
          key2 = cache.key('put', "http://example.com", "body2")
          expect(key1).to eq key2
      end
    end
  end

  describe 'key' do
    context 'with use_ignore_params set to false' do
      before do
        allow(Billy.config).to receive(:use_ignore_params) { false }
      end

      it "should use the same cache key if the base url IS NOT whitelisted in allow_params" do
        key1 = cache.key('put', params_url, 'body')
        key2 = cache.key('put', params_url, 'body')
        expect(key1).to eq key2
      end

      it "should have the same cache key if the base IS whitelisted in allow_params" do
        allow(Billy.config).to receive(:allow_params) { [base_url] }
        key1 = cache.key('put', params_url, 'body')
        key2 = cache.key('put', params_url, 'body')
        expect(key1).to eq key2
      end

      it "should have different cache keys if the base url is added in between two requests" do
        key1 = cache.key('put', params_url, 'body')
        allow(Billy.config).to receive(:allow_params) { [base_url] }
        key2 = cache.key('put', params_url, 'body')
        expect(key1).not_to eq key2
      end

      it "should not use ignore_params when whitelisted" do
        allow(Billy.config).to receive(:allow_params) { [base_url] }
        expect(cache).to receive(:format_url).once.with(params_url, true).and_call_original
        expect(cache).to receive(:format_url).once.with(params_url, false).and_call_original
        key1 = cache.key('put', params_url, 'body')
      end

      it "should use ignore_params when not whitelisted" do
        expect(cache).to receive(:format_url).twice.with(params_url, true).and_call_original
        cache.key('put', params_url, 'body')
      end
    end
  end
end
