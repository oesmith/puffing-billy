require 'billy'

module Billy
  module Browsers
    # Additional methods for Capybara
    class Capybara
      DRIVERS = {
        poltergeist: 'capybara/poltergeist',
        webkit: 'capybara/webkit',
        selenium: 'selenium/webdriver'
      }.freeze

      # Register proxy drivers
      def self.register_drivers
        DRIVERS.each do |name, driver|
          begin
            require driver
            send("register_#{name}_driver")
          rescue LoadError
          end
        end
      end

      # Register poltergeist with a proxy
      # @param options [Hash] the options to pass to the driver
      def self.register_poltergeist_driver(options = {})
        ::Capybara.register_driver :poltergeist_billy do |app|
          options.merge(
            phantomjs_options: [
              '--ignore-ssl-errors=yes',
              "--proxy=#{Billy.proxy.host}:#{Billy.proxy.port}"
            ]
          )
          ::Capybara::Poltergeist::Driver.new(app, options)
        end
      end

      # Register webkit with a proxy
      # @param options [Hash] the options to pass to the driver
      def self.register_webkit_driver(options = {})
        ::Capybara.register_driver :webkit_billy do |app|
          options.merge(
            ignore_ssl_errors: true,
            proxy: { host: Billy.proxy.host, port: Billy.proxy.port }
          )
          ::Capybara::Webkit::Driver.new(
            app,
            ::Capybara::Webkit::Configuration.to_hash.merge(options)
          )
        end
      end

      # Register selenium with a proxy
      def self.register_selenium_driver
        register_selenium_firefox
        register_selenium_chrome
      end

      # Register firefox with a proxy
      # @param profile [Capybara::WebDriver::Firefox::Profile] the profile
      # to pass to the driver
      def self.register_selenium_firefox(profile = nil)
        ::Capybara.register_driver :selenium_billy do |app|
          profile ||= Selenium::WebDriver::Firefox::Profile.new
          profile.assume_untrusted_certificate_issuer = false
          profile.proxy = Selenium::WebDriver::Proxy.new(
            http: "#{Billy.proxy.host}:#{Billy.proxy.port}",
            ssl: "#{Billy.proxy.host}:#{Billy.proxy.port}"
          )
          ::Capybara::Selenium::Driver.new(app, profile: profile)
        end
      end

      # Register chrome with a proxy
      # @param options [Capybara::WebDriver::Chrome::Options] the options
      # to pass to the driver
      def self.register_selenium_chrome(options = nil)
        ::Capybara.register_driver :selenium_chrome_billy do |app|
          options ||= Selenium::WebDriver::Chrome::Options.new
          options.add_argument(
            "--proxy-server=#{Billy.proxy.host}:#{Billy.proxy.port}"
          )

          ::Capybara::Selenium::Driver.new(
            app, browser: :chrome, options: options
          )
        end
      end
    end
  end
end
