require 'rspec'
require 'billy'

$billy_proxy = Billy::Proxy.new
$billy_proxy.start

module Billy
  def self.proxy
    $billy_proxy
  end

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

