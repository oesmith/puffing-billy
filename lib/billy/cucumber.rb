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

After('@billy') do
  proxy.reset
end
