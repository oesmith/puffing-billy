Dir[File.expand_path("../support/**/*.rb", __FILE__)].each {|f| require f}

require 'capybara/poltergeist'
require 'billy/rspec'
require 'capybara/rspec'
require 'rack'
require 'logger'

Capybara.app = Rack::Directory.new(File.expand_path("../../examples", __FILE__))
Capybara.javascript_driver = :poltergeist_billy

Billy.configure do |config|
  config.logger = Logger.new(File.expand_path("../../log/test.log", __FILE__))
end

RSpec.configure do |config|
  include Billy::TestServer
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'

  config.before :all do
    start_test_servers
  end
end
