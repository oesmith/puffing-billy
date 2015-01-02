require 'spec_helper'

describe Billy::Cache do
  describe 'format_url' do
    let(:cache) { Billy::Cache.instance }
    let(:params) { '?foo=bar' }
    let(:callback) { '&callback=quux' }
    let(:fragment) { '#baz' }
    let(:base_url) { 'http://example.com' }
    let(:fragment_url) { "#{base_url}/#{fragment}" }
    let(:params_url) { "#{base_url}#{params}" }
    let(:params_url_with_callback) { "#{base_url}#{params}#{callback}" }
    let(:params_fragment_url) { "#{base_url}#{params}#{fragment}" }

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
      context "when dynamic_jsonp is true" do
        it 'omits the callback param by default' do
          expect(cache.format_url(params_url_with_callback, false, true)).to eq params_url
        end

        it 'omits the params listed in Billy.config.dynamic_jsonp_keys' do
          allow(Billy.config).to receive(:dynamic_jsonp_keys) { ["foo"] }

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

    context "with merge_cached_responses_whitelist set" do

      let(:analytics_url1) { "http://www.example-analytics.com/user/SDF879932/" }
      let(:analytics_url2) { "http://www.example-analytics.com/user/OIWEMLW39/" }
      let(:regular_url) { "http://www.example-analytics.com/user.js" }

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
        expect(cache.key("post", analytics_url1, "body")).to eq cache.key("post", analytics_url2, "body")
        expect(cache.key("post", analytics_url1, "body")).not_to eq cache.key("post", regular_url, "body")
      end

      it "More specifically, the cache keys should be identical for the 2 analytics urls" do
        identical_cache_key = "post_5fcb7a450e4cd54dcffcb526212757ee0ca9dc17"
        distinct_cache_key = "post_www.example-analytics.com_81f097654a523bd7ddb10fd4aee781723e076a1a_02083f4579e08a612425c0c1a17ee47add783b94"

        expect(cache.key("post", analytics_url1, "body")).to eq identical_cache_key
        expect(cache.key("post", regular_url, "body")).to eq distinct_cache_key
        expect(cache.key("post", analytics_url2, "body")).to eq identical_cache_key
      end

    end
  end
end
