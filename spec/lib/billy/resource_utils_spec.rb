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
end