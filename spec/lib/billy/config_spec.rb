describe "Configuration" do
  it "allows billy to be configured" do
    require 'billy/rspec'

    Billy.configure do |config|
      config.cache_path = File.expand_path("../../../cache_dir", __FILE__)+"/"
      config.persist_cache = true
    end

    $billy_proxy = Billy::Proxy.new
    $billy_proxy.start

    $billy_proxy.instance_eval { @cache.fetch('get', 'https://example.com', '') }.should_not == nil
  end
end