# Puffing Billy

A stubbing proxy server for ruby. Connect it to your browser in integration tests to fake
interactions with remote HTTP(S) servers.

![](http://upload.wikimedia.org/wikipedia/commons/0/01/Puffing_Billy_1862.jpg)

## Overview

The thirty second version:

```ruby
it 'should stub google' do
  proxy.stub('http://www.google.com').and_return(:text => "I'm not Google!")
  visit 'http://www.google.com'
  page.should have_content("I'm not Google!")
end
```

## Installation

Add this line to your application's Gemfile:

    gem 'puffing-billy', :require => 'billy'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install puffing-billy

## Usage

In your `spec_helper.rb`:

```ruby
require 'billy/rspec'

# select a driver for your chosen browser environment
Capybara.javascript_driver = :selenium_billy
# Capybara.javascript_driver = :webkit_billy
# Capybara.javascript_driver = :poltergeist_billy
```

In your tests:

```ruby
# stub and return text, json, jsonp (or anything else)
proxy.stub('http://example.com/text').and_return(:text => 'Foobar')
proxy.stub('http://example.com/json').and_return(:json => { :foo => 'bar' })
proxy.stub('http://example.com/jsonp').and_return(:jsonp => { :foo => 'bar' })
proxy.stub('http://example.com/wtf').and_return(:body => 'WTF!?', :content_type => 'text/wtf')

# stub redirections and other return codes
proxy.stub('http://example.com/redirect').and_return(:redirect_to => 'http://example.com/other')
proxy.stub('http://example.com/missing').and_return(:code => 404, :body => 'Not found')

# even stub HTTPS!
proxy.stub('https://example.com/secure').and_return(:text => 'secrets!!1!')
```

Stubs are reset between tests.  Any requests that are not stubbed will be
proxied to the remote server.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## TODO

1. Integration for test frameworks other than rspec.
2. Caching (for super awesome improved test performance).
