require 'spec_helper'

describe Billy::ProxyRequestStub do
  context '#matches?' do
    it 'should match urls and methods' do
      Billy::ProxyRequestStub.new('http://example.com').
        matches?('GET', 'http://example.com').should be
      Billy::ProxyRequestStub.new('http://example.com').
        matches?('POST', 'http://example.com').should_not be
      Billy::ProxyRequestStub.new('http://example.com', :method => :get).
        matches?('GET', 'http://example.com').should be
      Billy::ProxyRequestStub.new('http://example.com', :method => :post).
        matches?('GET', 'http://example.com').should_not be
      Billy::ProxyRequestStub.new('http://example.com', :method => :post).
        matches?('POST', 'http://example.com').should be
      Billy::ProxyRequestStub.new('http://fooxample.com', :method => :post).
        matches?('POST', 'http://example.com').should_not be
    end

    it 'should match regexps' do
      Billy::ProxyRequestStub.new(/http:\/\/.+\.com/, :method => :post).
        matches?('POST', 'http://example.com').should be
      Billy::ProxyRequestStub.new(/http:\/\/.+\.co\.uk/, :method => :get).
        matches?('GET', 'http://example.com').should_not be
    end
  end

  context '#and_return + #call' do
    let(:subject) { Billy::ProxyRequestStub.new('url') }

    it 'should generate bare responses' do
      subject.and_return :body => 'baz foo bar'
      subject.call({}, {}, nil).should == [
        200,
        {},
        'baz foo bar'
      ]
    end

    it 'should generate text responses' do
      subject.and_return :text => 'foo bar baz'
      subject.call({}, {}, nil).should == [
        200,
        {'Content-Type' => 'text/plain'},
        'foo bar baz'
      ]
    end

    it 'should generate JSON responses' do
      subject.and_return :json => { :foo => 'bar' }
      subject.call({}, {}, nil).should == [
        200,
        {'Content-Type' => 'application/json'},
        '{"foo":"bar"}'
      ]
    end

    context 'JSONP' do
      it 'should generate JSONP responses' do
        subject.and_return :jsonp => { :foo => 'bar' }
        subject.call({ 'callback' => ['baz'] }, {}, nil).should == [
          200,
          {'Content-Type' => 'application/javascript'},
          'baz({"foo":"bar"})'
        ]
      end

      it 'should generate JSONP responses with custom callback parameter' do
        subject.and_return :jsonp => { :foo => 'bar' }, :callback_param => 'cb'
        subject.call({ 'cb' => ['bap'] }, {}, nil).should == [
          200,
          {'Content-Type' => 'application/javascript'},
          'bap({"foo":"bar"})'
        ]
      end

      it 'should generate JSONP responses with custom callback name' do
        subject.and_return :jsonp => { :foo => 'bar' }, :callback => 'cb'
        subject.call({}, {}, nil).should == [
          200,
          {'Content-Type' => 'application/javascript'},
          'cb({"foo":"bar"})'
        ]
      end
    end

    it 'should generate redirection responses' do
      subject.and_return :redirect_to => 'http://example.com'
      subject.call({}, {}, nil).should == [
        302,
        {'Location' => 'http://example.com'},
        nil
      ]
    end

    it 'should set headers' do
      subject.and_return :text => 'foo', :headers => {'HTTP-X-Foo' => 'bar'}
      subject.call({}, {}, nil).should == [
        200,
        {'Content-Type' => 'text/plain', 'HTTP-X-Foo' => 'bar'},
        'foo'
      ]
    end

    it 'should set status codes' do
      subject.and_return :text => 'baz', :code => 410
      subject.call({}, {}, nil).should == [
        410,
        {'Content-Type' => 'text/plain'},
        'baz'
      ]
    end

    it 'should use a callable' do
      expected_params = { 'param1' => ['one'], 'param2' => ['two'] }
      expected_headers = { 'header1' => 'three', 'header2' => 'four' }
      expected_body = 'body text'

      subject.and_return(Proc.new { |params, headers, body|
        params.should == expected_params
        headers.should == expected_headers
        body.should == 'body text'
        {:code => 418, :text => 'success'}
      })
      subject.call(expected_params, expected_headers, expected_body).should == [
        418,
        {'Content-Type' => 'text/plain'},
        'success'
      ]
    end
  end
end
