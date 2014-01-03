require "billy/version"
require "billy/config"
require "billy/proxy_request_stub"
require "billy/cache"
require "billy/proxy"
require "billy/proxy_connection"
require "billy/helpers"

module Billy
  def self.proxy
    @billy_proxy ||= (
      proxy = Billy::Proxy.new
      proxy.start
      proxy
    )
  end

  def self.register_drivers
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

    if defined?(Capybara::Webkit::Driver)
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
  end
end
