module Billy
  module RspecHelper
    def proxy
      Billy.proxy
    end
  end
end

RSpec.configure do |config|
  config.include(Billy::RspecHelper)

  config.prepend_after(:each) do
    proxy.reset
  end
end
