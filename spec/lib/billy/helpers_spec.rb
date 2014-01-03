require 'spec_helper'

describe Billy::Helpers do
  describe 'format_url' do
    let(:helper) { Billy::Helpers }
    let(:params) { '?foo=bar' }
    let(:fragment) { '#baz' }
    let(:base_url) { 'http://example.com' }
    let(:fragment_url) { "#{base_url}/#{fragment}" }
    let(:params_url) { "#{base_url}#{params}" }
    let(:params_fragment_url) { "#{base_url}#{params}#{fragment}" }

    context 'with ignore_params set to false' do
      it 'is a no-op if there are no params' do
        expect(helper.format_url(base_url)).to eq base_url
      end
      it 'appends params if there are params' do
        expect(helper.format_url(params_url)).to eq params_url
      end
      it 'appends params and fragment if both are present' do
        expect(helper.format_url(params_fragment_url)).to eq params_fragment_url
      end
    end

    context 'with ignore_params set to true' do
      it 'is a no-op if there are no params' do
        expect(helper.format_url(base_url, true)).to eq base_url
      end
      it 'omits params if there are params' do
        expect(helper.format_url(params_url, true)).to eq base_url
      end
      it 'omits params and fragment if both are present' do
        expect(helper.format_url(params_fragment_url, true)).to eq base_url
      end
    end
  end
end
