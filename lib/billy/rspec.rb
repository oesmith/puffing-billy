require 'rspec'
require 'capybara/rspec'
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

['capybara/poltergeist', 'capybara/webkit', 'selenium/webdriver'].each do |d|
  begin
    require d
  rescue LoadError
  end
end

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

if defined?(Capybara::Driver::Webkit)
  Capybara.register_driver :webkit_billy do |app|
    driver = Capybara::Webkit::Driver.new(app)
    driver.browser.set_proxy(:host => Billy.proxy.host,
                             :port => Billy.proxy.port)
    driver.browser.ignore_ssl_errors
    driver
  end
end

if defined?(Selenium::WebDriver)
  Capybara.register_driver :selenium_billy do |app|
    profile = Selenium::WebDriver::Firefox::Profile.new
    profile.proxy = Selenium::WebDriver::Proxy.new(
      :http => "#{Billy.proxy.host}:#{Billy.proxy.port}",
      :ssl => "#{Billy.proxy.host}:#{Billy.proxy.port}")
    Capybara::Selenium::Driver.new(app, :profile => profile)
  end
end
