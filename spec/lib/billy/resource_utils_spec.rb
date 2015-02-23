require 'spec_helper'

describe Billy::JSONUtils do
  describe 'sorting' do
    describe '#sort_hash_keys' do
      it 'sorts simple Hashes' do
        data     = { c: 'three', a: 'one', b: 'two' }
        expected = { a: 'one', b: 'two', c: 'three' }
        expect(Billy::JSONUtils.sort_hash_keys(data)).to eq expected
      end

      it 'does not sort simple Arrays' do
        data     = [3, 1, 2, 'two', 'three', 'one']
        expect(Billy::JSONUtils.sort_hash_keys(data)).to eq data
      end

      it 'does not sort multi-dimensional Arrays' do
        data     = [[3, 2, 1], [5, 4, 6], %w(b c a)]
        expect(Billy::JSONUtils.sort_hash_keys(data)).to eq data
      end

      it 'sorts multi-dimensional Hashes' do
        data     = { c: { l: 2, m: 3, k: 1 }, a: { f: 3, e: 2, d: 1 }, b: { i: 2, h: 1, j: 3 } }
        expected = { a: { d: 1, e: 2, f: 3 }, b: { h: 1, i: 2, j: 3 }, c: { k: 1, l: 2, m: 3 } }
        expect(Billy::JSONUtils.sort_hash_keys(data)).to eq expected
      end

      it 'sorts abnormal data structures' do
        data     = { b: [%w(b c a), { ab: 5, aa: 4, ac: 6 }, [3, 2, 1], { ba: true, bc: false, bb: nil }], a: { f: 3, e: 2, d: 1 } }
        expected = { a: { d: 1, e: 2, f: 3 }, b: [%w(b c a), { aa: 4, ab: 5, ac: 6 }, [3, 2, 1], { ba: true, bb: nil, bc: false }] }
        expect(Billy::JSONUtils.sort_hash_keys(data)).to eq expected
      end
    end

    describe 'sort_json' do
      it 'sorts JSON' do
        data     = '{"c":"three","a":"one","b":"two"}'
        expected = '{"a":"one","b":"two","c":"three"}'
        expect(Billy::JSONUtils.sort_json(data)).to eq expected
      end
    end
  end

  describe 'json?' do
    let(:json) { { a: '1' }.to_json }
    let(:non_json) { 'Not JSON.' }

    it 'identifies JSON' do
      expect(Billy::JSONUtils.json?(json)).to be true
    end
    it 'identifies non-JSON' do
      expect(Billy::JSONUtils.json?(non_json)).to be false
    end
  end
end
