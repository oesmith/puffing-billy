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

if defined?(Capybara)

  if defined?(Capybara::Poltergeist)
    Capybara.register_driver :poltergeist_billy do |app|
      options = {
        phantomjs_options: [
          '--ignore-ssl-errors=yes',
          "--proxy=#{Billy.proxy.host}:#{Billy.proxy.port}"
        ]
      }
      Capybara::Poltergeist::Driver.new(app, options)
    end
  end

  # TODO selenium / webkit
end
