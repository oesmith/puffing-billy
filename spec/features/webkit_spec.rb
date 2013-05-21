require 'spec_helper'

describe 'using the webkit driver', :type => :feature do
  before do
    Capybara.current_driver = :webkit_billy
  end

  it_behaves_like 'stubbing the Facebook API'
  it_behaves_like 'stubbing the Tumblr API'
end
