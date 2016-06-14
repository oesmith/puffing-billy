require 'billy'

module Billy
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
        options = {
          ignore_ssl_errors: true,
          proxy: {host: Billy.proxy.host, port: Billy.proxy.port}
        }
        Capybara::Webkit::Driver.new(app, Capybara::Webkit::Configuration.to_hash.merge(options))
      end
    end

    if defined?(Selenium::WebDriver)
      Capybara.register_driver :selenium_billy do |app|
        profile = Selenium::WebDriver::Firefox::Profile.new
        profile.assume_untrusted_certificate_issuer = false
        profile.proxy = Selenium::WebDriver::Proxy.new(
          http: "#{Billy.proxy.host}:#{Billy.proxy.port}",
          ssl: "#{Billy.proxy.host}:#{Billy.proxy.port}")
        Capybara::Selenium::Driver.new(app, profile: profile)
      end

      Capybara.register_driver :selenium_chrome_billy do |app|
        Capybara::Selenium::Driver.new(
          app, browser: :chrome,
          switches: ["--proxy-server=#{Billy.proxy.host}:#{Billy.proxy.port}"]
        )
      end
    end
  end
end
