require 'spec_helper'

describe Billy::Cache do
  describe 'format_url' do
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
  end
end
