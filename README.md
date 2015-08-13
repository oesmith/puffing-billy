# Puffing Billy

A rewriting web proxy for testing interactions between your browser and
external sites. Works with ruby + rspec.

Puffing Billy is like [webmock](https://github.com/bblimke/webmock) or
[VCR](https://github.com/vcr/vcr), but for your browser.

![](http://upload.wikimedia.org/wikipedia/commons/0/01/Puffing_Billy_1862.jpg)

## Overview

Billy spawns an EventMachine-based proxy server, which it uses to intercept
requests sent by your browser. It has a simple API for configuring which
requests need stubbing and what they should return.

Billy lets you test against known, repeatable data.  It also allows you to
test for failure cases.  Does your twitter (or facebook/google/etc)
integration degrade gracefully when the API starts returning 500s?  Well now
you can test it!

```ruby
it 'should stub google' do
  proxy.stub('http://www.google.com/').and_return(:text => "I'm not Google!")
  visit 'http://www.google.com/'
  page.should have_content("I'm not Google!")
end
```

You can also record HTTP interactions and replay them later. See
[caching](#caching) below.

## Installation

Add this line to your application's Gemfile:

    gem 'puffing-billy'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install puffing-billy

## RSpec Usage

In your `rails_helper.rb`:

```ruby
require 'billy/rspec'

# select a driver for your chosen browser environment
Capybara.javascript_driver = :selenium_billy # Uses Firefox
# Capybara.javascript_driver = :selenium_chrome_billy
# Capybara.javascript_driver = :webkit_billy
# Capybara.javascript_driver = :poltergeist_billy
```

Note: :poltergeist_billy doesn't support proxying any localhosts, so you must use
:webkit_billy for headless specs when using puffing-billy for other local rack apps.
See [this phantomjs issue](https://github.com/ariya/phantomjs/issues/11342) for any updates.

In your tests:

```ruby
# Stub and return text, json, jsonp (or anything else)
proxy.stub('http://example.com/text/').and_return(:text => 'Foobar')
proxy.stub('http://example.com/json/').and_return(:json => { :foo => 'bar' })
proxy.stub('http://example.com/jsonp/').and_return(:jsonp => { :foo => 'bar' })
proxy.stub('http://example.com/headers/').and_return({
  :headers => { 'Access-Control-Allow-Origin' => '*' },
  :json    => { :foo => 'bar' }
})
proxy.stub('http://example.com/wtf/').and_return(:body => 'WTF!?', :content_type => 'text/wtf')

# Stub redirections and other return codes
proxy.stub('http://example.com/redirect/').and_return(:redirect_to => 'http://example.com/other')
proxy.stub('http://example.com/missing/').and_return(:code => 404, :body => 'Not found')

# Even stub HTTPS!
proxy.stub('https://example.com:443/secure/').and_return(:text => 'secrets!!1!')

# Pass a Proc (or Proc-style object) to create dynamic responses.
#
# The proc will be called with the following arguments:
#   params:  Query string parameters hash, CGI::escape-style
#   headers: Headers hash
#   body:    Request body string
#
proxy.stub('https://example.com/proc/').and_return(Proc.new { |params, headers, body|
  { :text => "Hello, #{params['name'][0]}"}
})
```

Stubs are reset between tests.  Any requests that are not stubbed will be
proxied to the remote server.

## Cucumber Usage

In your `features/support/env.rb`:

```ruby
require 'billy/cucumber'

After do
  Capybara.use_default_driver
end
```

An example feature:

```
Feature: Stubbing via billy

  @javascript @billy
  Scenario: Test billy
    And a stub for google
```

And in steps:

```ruby
Before('@billy') do
  Capybara.current_driver = :poltergeist_billy
end

And /^a stub for google$/ do
  proxy.stub('http://www.google.com/').and_return(:text => "I'm not Google!")
  visit 'http://www.google.com/'
  page.should have_content("I'm not Google!")
end
```

It's good practice to reset the driver after each scenario, so having an
`@billy` tag switches the drivers on for a given scenario. Also note that
stubs are reset after each step, so any usage of a stub should be in the
same step that it was created in.

## Minitest Usage

Please see [this link](https://gist.github.com/sauy7/1b081266dd453a1b737b) for
details and report back to [Issue #49](https://github.com/oesmith/puffing-billy/issues/49)
if you get it fully working.

## Caching

Requests routed through the external proxy are cached.

By default, all requests to localhost or 127.0.0.1 will not be cached. If
you're running your test server with a different hostname, you'll need to
add that host to puffing-billy's whitelist.

In your `rails_helper.rb`:

```ruby
Billy.configure do |c|
  c.whitelist = ['test.host', 'localhost', '127.0.0.1']
end
```

If you would like to cache other local rack apps, you must whitelist only the
specific port for the application that is executing tests.  If you are using
[Capybara](https://github.com/jnicklas/capybara), this can be accomplished by
adding this in your `rails_helper.rb`:

```ruby
server = Capybara.current_session.server
Billy.config.whitelist = ["#{server.host}:#{server.port}"]
```

If you want to use puffing-billy like you would [VCR](https://github.com/vcr/vcr)
you can turn on cache persistence. This way you don't have to manually mock out
everything as requests are automatically recorded and played back. With cache
persistence you can take tests completely offline.

```ruby
Billy.configure do |c|
  c.cache = true
  c.cache_request_headers = false
  c.ignore_params = ["http://www.google-analytics.com/__utm.gif",
                     "https://r.twimg.com/jot",
                     "http://p.twitter.com/t.gif",
                     "http://p.twitter.com/f.gif",
                     "http://www.facebook.com/plugins/like.php",
                     "https://www.facebook.com/dialog/oauth",
                     "http://cdn.api.twitter.com/1/urls/count.json"]
  c.path_blacklist = []
  c.merge_cached_responses_whitelist = []
  c.persist_cache = true
  c.ignore_cache_port = true # defaults to true
  c.non_successful_cache_disabled = false
  c.non_successful_error_level = :warn
  c.non_whitelisted_requests_disabled = false
  c.cache_path = 'spec/req_cache/'
  c.proxy_host = 'example.com' # defaults to localhost
  c.proxy_port = 12345 # defaults to random
end
```

The cache works with all types of requests and will distinguish between
different POST requests to the same URL.

`c.cache_request_headers` is used to store the outgoing request headers in the cache.
It is also saved to yml if `persist_cache` is enabled.  This additional information
is useful for debugging (for example: viewing the referer of the request).

`c.ignore_params` is used to ignore parameters of certain requests when
caching. You should mostly use this for analytics and various social buttons as
they use cache avoidance techniques, but return practically the same response
that most often does not affect your test results.

`c.strip_query_params` is used to strip query parameters when you stub some requests
with query parameters. Default value is true. For example, `proxy.stub('http://myapi.com/user/?country=FOO')`
is considered the same as: `proxy.stub('http://myapi.com/user/?anything=FOO')` and
generally the same as: `proxy.stub('http://myapi.com/user/')`. When you need to distinguish between all these requests,
you may set this config value to false.

`c.dynamic_jsonp` is used to rewrite the body of JSONP responses based on the
callback parameter. For example, if a request to `http://example.com/foo?callback=bar`
returns `bar({"some": "json"});` and is recorded, then a later request to
`http://example.com/foo?callback=baz` will be a cache hit and respond with
`baz({"some": "json"});` This is useful because most JSONP implementations
base the callback name off of a timestamp or something else dynamic.

`c.dynamic_jsonp_keys` is used to configure which parameters to ignore when
using `c.dynamic_jsonp`. This is helpful when JSONP APIs use cache-busting
parameters. For example, if you want `http://example.com/foo?callback=bar&id=1&cache_bust=12345` and `http://example.com/foo?callback=baz&id=1&cache_bust=98765` to be cache hits for each other, you would set `c.dynamic_jsonp_keys = ['callback', 'cache_bust']` to ignore both params. Note
that in this example the `id` param would still be considered important.

`c.path_blacklist = []` is used to always cache specific paths on any hostnames,
including whitelisted ones.  This is useful if your AUT has routes that get data
from external services, such as `/api` where the ajax request is a local URL but
the actual data is coming from a different application that you want to cache.

`c.merge_cached_responses_whitelist = []` is used to group together the cached
responses for specific uri regexes that match any part of the url. This is useful
for ensuring that any kind of analytics and various social buttons that have
slightly different urls each time can be recorded once and reused nicely. Note
that the request body is ignored for requests that contain a body.

`c.ignore_cache_port` is used to strip the port from the URL if it exists.  This
is useful when caching local paths (via `path_blacklist`) or other local rack apps
that are running on random ports.

`c.non_successful_cache_disabled` is used to not cache responses without 200-series
or 304 status codes.  This prevents unauthorized or internal server errors from
being cached and used for future test runs.

`c.non_successful_error_level` is used to log when non-successful resposnes are
received.  By default, it just writes to the log file, but when set to `:error`
it throws an error with the URL and status code received for easier debugging.

`c.non_whitelisted_requests_disabled` is used to disable hitting new URLs when
no cache file exists.  Only whitelisted URLs (on non-blacklisted paths) are
allowed, all others will throw an error with the URL attempted to be accessed.
This is useful for debugging issues in isolated environments (ie.
continuous integration).

### Cache Scopes

If you need to cache different responses to the same HTTP request, you can use
cache scoping.

For example, an index page may return zero or more items in a list, with or
without pagination, depending on the number of entries in a database.

There are a few different ways to use cache scopes:

```ruby
# If you do nothing, it uses the default cache scope:
it 'defaults to nil scope' do
  expect(proxy.cache.scope).to be_nil
end

# You can change context indefinitely to a specific cache scope:
context 'with a cache scope' do
  before do
    proxy.cache.scope_to "my_cache"
  end

  # Remember to set the cache scope back to the default in an after block
  # within the context it is used, and/or at the global rails_helper level!
  after do
    proxy.cache.use_default_scope
  end

  it 'uses the cache scope' do
    expect(proxy.cache.scope).to eq("my_cache")
  end

  it 'can be reset to the default scope' do
    proxy.cache.use_default_scope
    expect(proxy.cache.scope).to be_nil
  end

  # Or you can run a block within the context of a cache scope:
  # Note: When using scope blocks, be sure that both the action that triggers a
  #       request and the assertion that a response has been received are within the block
  it 'can execute a block against a named cache' do
    expect(proxy.cache.scope).to eq("my_cache")
    proxy.cache.with_scope "another_cache" do
      expect(proxy.cache.scope).to eq "another_cache"
    end
    # It
    expect(proxy.cache.scope).to eq("my_cache")
  end
end
```

If you use named caches it is highly recommend that you use a global
hook to set the cache back to the default before or after each test.

In Rspec:

```ruby
RSpec.configure do |config|
  config.before :each { proxy.cache.use_default_scope }
end
```

## Proxy timeouts

By default, the Puffing Billy proxy will use the EventMachine:HttpRequest timeouts of 5 seconds
for connect and 10 seconds for inactivity when talking to downstream servers.

These can be configured as follows:

```ruby
Billy.configure do |c|
  c.proxied_request_connect_timeout = 20
  c.proxied_request_inactivity_timeout = 20
end
```

## Customising the javascript driver

If you use a customised Capybara driver, remember to set the proxy address
and tell it to ignore SSL certificate warnings. See
[lib/billy.rb](https://github.com/oesmith/puffing-billy/blob/master/lib/billy.rb)
to see how Billy's default drivers are configured.

## Working with VCR and Webmock
If you use VCR and Webmock elsewhere in your specs, you may need to disable them
for your specs utilizing Puffing Billy. To do so, you can configure your `rails_helper.rb`
as shown below:

```ruby
RSpec.configure do |config|
  config.around(:each, type: :feature) do |example|
    WebMock.allow_net_connect!
    VCR.turned_off { example.run }
    WebMock.disable_net_connect!
  end
end
```

## Resources

* [Bring Ruby VCR to Javascript testing with Capybara and puffing-billy](http://architects.dzone.com/articles/bring-ruby-vcr-javascript)
* [Integration Testing Stripe.js With Mocked Network Requests](http://dev.contractual.ly/testing-stripe-js-with-mocked-network/)
* [Clean-up unused cache files periodically with this config](https://github.com/oesmith/puffing-billy/pull/26#issuecomment-29905030)

## FAQ

1. Why name it after a train?

   Trains are *cool*.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## TODO

1. Integration for test frameworks other than rspec.
2. Show errors from the EventMachine reactor loop in the test output.

