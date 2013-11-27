require 'spec_helper'
include Billy::ResourceUtils

describe Billy::ResourceUtils do
  describe 'sorting' do
    describe '#sort_json_data' do
      it 'sorts simple Hashes' do
        data     = {c: 'three',a: 'one',b: 'two'}
        expected = {a: 'one',b: 'two',c: 'three'}
        expect(Billy::ResourceUtils.sort_json_data(data)).to eq expected
      end

      it 'sorts simple Arrays' do
        data     = [3,1,2,'two','three','one']
        expected = [1,2,3,'one','three','two']
        expect(Billy::ResourceUtils.sort_json_data(data)).to eq expected
      end

      it 'sorts multi-dimensional Arrays' do
        data     = [[3,2,1],[5,4,6],['b','c','a']]
        expected = [['a','b','c'],[1,2,3],[4,5,6]]
        expect(Billy::ResourceUtils.sort_json_data(data)).to eq expected
      end

      it 'sorts multi-dimensional Hashes' do
        data     = {c: {l: 2,m: 3,k: 1},a: {f: 3,e: 2,d: 1},b: {i: 2,h: 1,j: 3}}
        expected = {a: {d: 1,e: 2,f: 3},b: {h: 1,i: 2,j: 3},c: {k: 1,l: 2,m: 3}}
        expect(Billy::ResourceUtils.sort_json_data(data)).to eq expected
      end

      it 'sorts abnormal data structures' do
        data     = {b: [['b','c','a'],{ab: 5,aa: 4, ac: 6},[3,2,1],{ba: true,bc: false, bb: nil}],a: {f: 3,e: 2,d: 1}}
        expected = {a: {d: 1,e: 2,f: 3},b: [['a','b','c'],[1,2,3],{aa: 4,ab: 5,ac: 6},{ba: true, bb: nil,bc: false}]}
        expect(Billy::ResourceUtils.sort_json_data(data)).to eq expected
      end
    end

    describe 'sort_json' do
      it 'sorts JSON' do
        data     = '{"c":"three","a":"one","b":"two"}'
        expected = '{"a":"one","b":"two","c":"three"}'
        expect(sort_json(data)).to eq expected
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

  describe 'format_url' do
    let(:params) { '?foo=bar' }
    let(:fragment) { '#baz' }
    let(:base_url) { 'http://example.com' }
    let(:fragment_url) { "#{base_url}/#{fragment}" }
    let(:params_url) { "#{base_url}#{params}" }
    let(:params_fragment_url) { "#{base_url}#{params}#{fragment}" }

    context 'with include_params' do
      it 'is a no-op if there are no params' do
        expect(format_url(base_url, true)).to eq base_url
      end
      it 'appends params if there are params' do
        expect(format_url(params_url, true)).to eq params_url
      end
      it 'appends params and anchor if both are present' do
        expect(format_url(params_fragment_url, true)).to eq params_fragment_url
      end
    end

    context 'without include_params' do
      it 'is a no-op if there are no params' do
        expect(format_url(base_url, false)).to eq base_url
      end
      it 'omits params if there are params' do
        expect(format_url(params_url, false)).to eq base_url
      end
      it 'omits params and anchor if both are present' do
        expect(format_url(params_fragment_url, false)).to eq base_url
      end
    end
  end
end