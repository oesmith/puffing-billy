require 'spec_helper'
require 'puffing-billy'

describe Billy::Proxy do

  before do
    @proxy = Billy::Proxy.new
    @proxy.start
    @http = Faraday.new @http_url, :proxy => { :uri => @proxy.url }, :timeout => 2
    @https = Faraday.new @https_url, :proxy => { :uri => @proxy.url }, :ssl => { :validate => false }
  end

  describe 'proxying' do
    it 'should proxy HTTP' do
      @http.get('/echo').body.should == 'GET /echo'
    end

    it 'should proxy HTTPS' do
      @https.get('/echo').body.should == 'GET /echo'
    end
  end

end
