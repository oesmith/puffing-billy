require 'rspec'
require 'capybara/rspec'
require 'billy'

Billy.register_drivers

module Billy
  module RspecHelper
    def proxy
      Billy.proxy
    end
  end
end

RSpec.configure do |config|
  config.include(Billy::RspecHelper)

  config.before(:each) do
    if Capybara.current_driver == :webkit_billy
      Capybara.page.driver.browser.set_proxy(
        :host => Billy.proxy.host,
        :port => Billy.proxy.port)
    end
  end

  config.after(:each) do
    proxy.reset
  end
end
