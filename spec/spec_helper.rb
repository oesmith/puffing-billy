Dir[File.expand_path('../support/**/*.rb', __FILE__)].each { |f| require f }

require 'pry'
require 'billy/capybara/rspec'
require 'billy/watir/rspec'
require 'rack'
require 'logger'
require 'fileutils'
require 'webdrivers'

$stdout.puts `#{::Selenium::WebDriver::Chrome::Service.driver_path.call} --version` if ENV['CI']

browser = Billy::Browsers::Watir.new :chrome

Capybara.configure do |config|
  config.app = Rack::Directory.new(File.expand_path('../../examples', __FILE__))
  config.server = :webrick
  config.javascript_driver = :selenium_chrome_headless_billy
end

Billy.configure do |config|
  config.logger = Logger.new(File.expand_path('../../log/test.log', __FILE__))
end

RSpec.configure do |config|
  include Billy::TestServer
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'

  config.before :suite do
    FileUtils.rm_rf(Billy.config.certs_path)
    FileUtils.rm_rf(Billy.config.cache_path)
  end

  config.before :all do
    start_test_servers
    @browser = browser
  end

  config.before :each do
    proxy.reset_cache
  end

  config.after :each do
    Billy.config.reset
  end

  config.after :suite do
    browser.close
  end
end
