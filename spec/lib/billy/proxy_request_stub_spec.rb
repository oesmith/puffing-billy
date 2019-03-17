require 'spec_helper'

describe Billy::ProxyRequestStub do
  context '#matches?' do
    it 'should match urls and methods' do
      expect(Billy::ProxyRequestStub.new('http://example.com')
        .matches?('GET', 'http://example.com')).to be
      expect(Billy::ProxyRequestStub.new('http://example.com')
        .matches?('POST', 'http://example.com')).to_not be

      expect(Billy::ProxyRequestStub.new('http://example.com', method: :get)
        .matches?('GET', 'http://example.com')).to be
      expect(Billy::ProxyRequestStub.new('http://example.com', method: :post)
        .matches?('GET', 'http://example.com')).to_not be
      expect(Billy::ProxyRequestStub.new('http://example.com', method: :options)
        .matches?('GET', 'http://example.com')).to_not be

      expect(Billy::ProxyRequestStub.new('http://example.com', method: :post)
        .matches?('POST', 'http://example.com')).to be
      expect(Billy::ProxyRequestStub.new('http://fooxample.com', method: :post)
        .matches?('POST', 'http://example.com')).to_not be
        expect(Billy::ProxyRequestStub.new('http://fooxample.com', method: :options)
          .matches?('POST', 'http://example.com')).to_not be

      expect(Billy::ProxyRequestStub.new('http://example.com', method: :options)
        .matches?('OPTIONS', 'http://example.com')).to be
      expect(Billy::ProxyRequestStub.new('http://example.com', method: :options)
        .matches?('OPTIONS', 'http://zzzzzexample.com')).to_not be
      expect(Billy::ProxyRequestStub.new('http://example.com', method: :post)
        .matches?('OPTIONS', 'http://example.com')).to_not be
    end

    it 'should match regexps' do
      expect(Billy::ProxyRequestStub.new(/http:\/\/.+\.com/, method: :post)
        .matches?('POST', 'http://example.com')).to be
      expect(Billy::ProxyRequestStub.new(/http:\/\/.+\.co\.uk/, method: :get)
        .matches?('GET', 'http://example.com')).to_not be
    end

    it 'should match up to but not including query strings' do
      stub = Billy::ProxyRequestStub.new('http://example.com/foo/bar/')
      expect(stub.matches?('GET', 'http://example.com/foo/')).to_not be
      expect(stub.matches?('GET', 'http://example.com/foo/bar/')).to be
      expect(stub.matches?('GET', 'http://example.com/foo/bar/?baz=bap')).to be
    end

    it 'should match all methods' do
      expect(Billy::ProxyRequestStub.new('http://example.com', method: :all)
        .matches?('GET', 'http://example.com')).to be
      expect(Billy::ProxyRequestStub.new('http://example.com', method: :all)
        .matches?('POST', 'http://example.com')).to be
      expect(Billy::ProxyRequestStub.new('http://example.com', method: :all)
        .matches?('OPTIONS', 'http://example.com')).to be
      expect(Billy::ProxyRequestStub.new('http://example.com', method: :all)
        .matches?('HEAD', 'http://example.com')).to be
    end
  end

  context "#matches? (with strip_query_params false in config)" do
    before do
      Billy.config.strip_query_params = false
    end

    it 'should not match up to request with query strings' do
      stub = Billy::ProxyRequestStub.new('http://example.com/foo/bar/')
      expect(stub.matches?('GET', 'http://example.com/foo/')).to_not be
      expect(stub.matches?('GET', 'http://example.com/foo/bar/')).to be
      expect(stub.matches?('GET', 'http://example.com/foo/bar/?baz=bap')).to_not be
    end
  end

  context '#call (without #and_return)' do
    let(:subject) { Billy::ProxyRequestStub.new('url') }

    it 'returns a 204 empty response' do
      expect(subject.call('', '', {}, {}, nil)).to eql [204, { 'Content-Type' => 'text/plain' }, '']
    end
  end

  context '#and_return + #call' do
    let(:subject) { Billy::ProxyRequestStub.new('url') }

    it 'should generate bare responses' do
      subject.and_return body: 'baz foo bar'
      expect(subject.call('', '', {}, {}, nil)).to eql [
        200,
        {},
        'baz foo bar'
      ]
    end

    it 'should generate text responses' do
      subject.and_return text: 'foo bar baz'
      expect(subject.call('', '', {}, {}, nil)).to eql [
        200,
        { 'Content-Type' => 'text/plain' },
        'foo bar baz'
      ]
    end

    it 'should generate JSON responses' do
      subject.and_return json: { foo: 'bar' }
      expect(subject.call('', '', {}, {}, nil)).to eql [
        200,
        { 'Content-Type' => 'application/json' },
        '{"foo":"bar"}'
      ]
    end

    context 'JSONP' do
      it 'should generate JSONP responses' do
        subject.and_return jsonp: { foo: 'bar' }
        expect(subject.call('', '', { 'callback' => ['baz'] }, {}, nil)).to eql [
          200,
          { 'Content-Type' => 'application/javascript' },
          'baz({"foo":"bar"})'
        ]
      end

      it 'should generate JSONP responses with custom callback parameter' do
        subject.and_return jsonp: { foo: 'bar' }, callback_param: 'cb'
        expect(subject.call('', '', { 'cb' => ['bap'] }, {}, nil)).to eql [
          200,
          { 'Content-Type' => 'application/javascript' },
          'bap({"foo":"bar"})'
        ]
      end

      it 'should generate JSONP responses with custom callback name' do
        subject.and_return jsonp: { foo: 'bar' }, callback: 'cb'
        expect(subject.call('', '', {}, {}, nil)).to eql [
          200,
          { 'Content-Type' => 'application/javascript' },
          'cb({"foo":"bar"})'
        ]
      end
    end

    it 'should generate redirection responses' do
      subject.and_return redirect_to: 'http://example.com'
      expect(subject.call('', '', {}, {}, nil)).to eql [
        302,
        { 'Location' => 'http://example.com' },
        nil
      ]
    end

    it 'should set headers' do
      subject.and_return text: 'foo', headers: { 'HTTP-X-Foo' => 'bar' }
      expect(subject.call('', '', {}, {}, nil)).to eql [
        200,
        { 'Content-Type' => 'text/plain', 'HTTP-X-Foo' => 'bar' },
        'foo'
      ]
    end

    it 'should set status codes' do
      subject.and_return text: 'baz', code: 410
      expect(subject.call('', '', {}, {}, nil)).to eql [
        410,
        { 'Content-Type' => 'text/plain' },
        'baz'
      ]
    end

    it 'should use a callable' do
      expected_params = { 'param1' => ['one'], 'param2' => ['two'] }
      expected_headers = { 'header1' => 'three', 'header2' => 'four' }
      expected_body = 'body text'

      subject.and_return(proc do |params, headers, body, url, method|
        expect(params).to eql expected_params
        expect(headers).to eql expected_headers
        expect(body).to eql 'body text'
        expect(url).to eql 'url'
        expect(method).to eql 'GET'
        { code: 418, text: 'success' }
      end)
      expect(subject.call('GET', 'url', expected_params, expected_headers, expected_body)).to eql [
        418,
        { 'Content-Type' => 'text/plain' },
        'success'
      ]
    end

    it 'should use a callable with Billy.pass_request' do
      # Add the missing em-synchrony call which is done by
      # ProxyConnection#handle_request instead.
      EM.synchrony do
        subject.and_return(proc do |*args|
          response = Billy.pass_request(*args)
          response[:body] = 'modified'
          response[:code] = 205
          response
        end)

        # The test server can't be used at this scenario due to the limitations
        # of the Ruby GIL. We cannot use fibers (via eventmachine) and ask
        # ourself on a different thread to serve a HTTP request. This results
        # in +fiber called across threads (FiberError)+ errors. Unfortunately
        # we have to ask an external resource.
        url = 'http://google.com'

        expect(subject.call('GET', url, {}, {}, 'original')).to eql [
          205,
          'modified'
        ]
      end
    end
  end

  context '#stub_requests' do
    let(:subject) { Billy::ProxyRequestStub.new('url') }

    before :each do
      Billy.config.record_stub_requests = true
    end

    it 'should record requests' do
      subject.call('', '', {}, {}, nil)
      expect(subject.has_requests?).to be true
    end

    it 'should record multiple requests' do
      expected_amount = 3
      expected_amount.times do
        subject.call('', '', {}, {}, nil)
      end

      expect(subject.requests.length).to eql expected_amount
    end

    it 'should set a request' do
      expected_request = {
        method: 'POST',
        url: 'test-url',
        params: { 'param1' => ['one'], 'param2' => ['two'] },
        headers: { 'header1' => 'three', 'header2' => 'four' },
        body: 'body text'
      }

      subject.call(
        expected_request[:method],
        expected_request[:url],
        expected_request[:params],
        expected_request[:headers],
        expected_request[:body]
      )
      expect(subject.requests[0]).to eql expected_request
    end
  end
end
