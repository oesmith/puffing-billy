require 'cucumber'
require 'capybara/cucumber'
require 'billy'

Billy.register_drivers

module Billy
  module CucumberHelper
    def proxy
      Billy.proxy
    end
  end
end

World(Billy::CucumberHelper)

Before('@billy') do
  if Capybara.current_driver == :webkit_billy
    Capybara.page.driver.browser.set_proxy(
      :host => Billy.proxy.host,
      :port => Billy.proxy.port)
  end
end

After('@billy') do
  proxy.reset
end
