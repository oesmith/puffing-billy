require 'spec_helper'
require 'puffing-billy'

describe Billy::Proxy do

  describe 'proxying' do
    it 'should proxy HTTP' do
      @http.get('/echo').body.should == 'GET /echo'
    end

    it 'should proxy HTTPS' do
      @https.get('/echo').body.should == 'GET /echo'
    end
  end

end
