require 'spec_helper'

describe Billy::ProxyConnection do
  context '#prepare_response_headers_for_evma_httpserver' do
    let(:subject) { Billy::ProxyConnection.new('') }
    
    it 'should remove duplicated headers fields' do
        provided_headers = {
            'transfer-encoding' => '',
            'content-length' => '',
            'content-encoding' => '',
            'key' => 'value'
        }
        expected_headers = { 'key' => 'value' }
        headers = subject.send(:prepare_response_headers_for_evma_httpserver, provided_headers)

        expect(headers).to eql expected_headers
    end
  end
end
