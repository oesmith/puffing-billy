module Billy
  module RspecHelper
    def proxy
      Billy.proxy
    end
  end
end

RSpec.configure do |config|
  config.include(Billy::RspecHelper)

  config.append_after(:each) do
    proxy.reset
  end

  config.after(:suite) do
    Billy.proxy.stop
  end
end
