require 'spec_helper'
require 'puffing-billy'
require 'eventmachine'
require 'evma_httpserver'
require 'faraday'

class Echo < EM::Connection
  include EM::HttpServer

  def post_init
    super
    no_environment_strings
  end

  def process_http_request
    response = EM::DelegatedHttpResponse.new(self)
    response.status = 200
    response.content_type 'text/plain'
    response.content = @http_request_uri
    response.send_response
  end
end

describe Billy::Proxy do

  before(:all) do
    q = Queue.new
    t = Thread.new do
      EM.run do
        server = EM.start_server '127.0.0.1', 0, Echo
        puts server.class.name
        q.push server
      end
    end
    @server = q.pop
    puts @server
  end

  describe 'proxying' do
    it 'should proxy HTTP' do
      response = Faraday.get 'http://localhost:1234/echo'
      response.body.should == 'echo'
    end
  end

end
