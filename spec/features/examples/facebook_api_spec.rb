require 'spec_helper'
require 'base64'

describe 'Facebook API example', :type => :feature, :js => true do
  before do
    proxy.stub('https://www.facebook.com:443/dialog/oauth').and_return(Proc.new { |params,_,_|
      # mock a signed request from facebook.  the JS api never verifies the
      # signature, so all it needs is the base64-encoded payload
      signed_request = "xxxxxxxxxx.#{Base64.encode64('{"user_id":"1234567"}')}"
      # redirect to the 'redirect_uri', with some extra crap in the query string
      {:redirect_to => "#{params['redirect_uri'][0]}&access_token=foobar&expires_in=600&base_domain=localhost&https=1&signed_request=#{signed_request}"}
    })

    proxy.stub('https://graph.facebook.com:443/me').and_return(:jsonp => {:name => 'Tester 1'})
  end

  it 'should show me as logged-in' do
    visit '/facebook_api.html'
    click_on "Login"
    expect(page).to have_content "Hi, Tester 1"
  end
end
