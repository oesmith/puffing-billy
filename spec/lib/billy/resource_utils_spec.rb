require 'spec_helper'
include Billy::ResourceUtils

describe Billy::ResourceUtils do
  describe 'sorting' do
    let!(:helper) { ResourceUtilsSpecHelper }
    let(:sorted_hash_1_level) { helper.sorted_hash_1_level }
    let(:sorted_hash_2_level) { helper.sorted_hash_2_level }
    let(:unsorted_hash_1_level) { helper.unsorted_hash_1_level }
    let(:unsorted_hash_2_level) { helper.unsorted_hash_2_level }

    describe 'sorted_hash' do
      it 'sorts nested hashes 1 level deep' do
        expect(sorted_hash(unsorted_hash_1_level)).to eq sorted_hash_1_level
      end
      it 'sorts nested hashes 2 levels deep' do
        expect(sorted_hash(unsorted_hash_2_level)).to eq sorted_hash_2_level
      end
    end

    describe 'sorted_json' do
      it 'sorts nested JSON 1 level deep' do
        expect(sorted_json(unsorted_hash_1_level.to_json)).to eq sorted_hash_1_level.to_json
      end
      it 'sorts nested JSON 2 levels deep' do
        expect(sorted_json(unsorted_hash_2_level.to_json)).to eq sorted_hash_2_level.to_json
      end
    end
  end

  describe 'json?' do
    let(:json) { {a: '1'}.to_json }
    let(:non_json) { 'Not JSON.' }

    it 'identifies JSON' do
      expect(json?(json)).to be_true
    end
    it 'identifies non-JSON' do
      expect(json?(non_json)).to be_false
    end
  end

  describe 'url_formatted' do
    let(:params) { '?foo=bar' }
    let(:fragment) { '#baz' }
    let(:base_url) { 'http://example.com' }
    let(:fragment_url) { "#{base_url}/#{fragment}" }
    let(:params_url) { "#{base_url}#{params}" }
    let(:params_fragment_url) { "#{base_url}#{params}#{fragment}" }

    context 'with include_params' do
      it 'is a no-op if there are no params' do
        expect(url_formatted(base_url, true)).to eq base_url
      end
      it 'appends params if there are params' do
        expect(url_formatted(params_url, true)).to eq params_url
      end
      it 'appends params and anchor if both are present' do
        expect(url_formatted(params_fragment_url, true)).to eq params_fragment_url
      end
    end

    context 'without include_params' do
      it 'is a no-op if there are no params' do
        expect(url_formatted(base_url, false)).to eq base_url
      end
      it 'omits params if there are params' do
        expect(url_formatted(params_url, false)).to eq base_url
      end
      it 'omits params and anchor if both are present' do
        expect(url_formatted(params_fragment_url, false)).to eq base_url
      end
    end
  end
end