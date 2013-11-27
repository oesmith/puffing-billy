require 'spec_helper'

describe Billy::Cache do
  describe 'format_url' do
    let(:cache) { Billy::Cache.new }
    let(:params) { '?foo=bar' }
    let(:fragment) { '#baz' }
    let(:base_url) { 'http://example.com' }
    let(:fragment_url) { "#{base_url}/#{fragment}" }
    let(:params_url) { "#{base_url}#{params}" }
    let(:params_fragment_url) { "#{base_url}#{params}#{fragment}" }

    context 'with include_params' do
      it 'is a no-op if there are no params' do
        expect(cache.format_url(base_url, true)).to eq base_url
      end
      it 'appends params if there are params' do
        expect(cache.format_url(params_url, true)).to eq params_url
      end
      it 'appends params and anchor if both are present' do
        expect(cache.format_url(params_fragment_url, true)).to eq params_fragment_url
      end
    end

    context 'without include_params' do
      it 'is a no-op if there are no params' do
        expect(cache.format_url(base_url, false)).to eq base_url
      end
      it 'omits params if there are params' do
        expect(cache.format_url(params_url, false)).to eq base_url
      end
      it 'omits params and anchor if both are present' do
        expect(cache.format_url(params_fragment_url, false)).to eq base_url
      end
    end
  end
end