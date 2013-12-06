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

  config.after(:each) do
    proxy.reset
  end
end
