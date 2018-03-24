require 'billy'

module Billy
  module Browsers
    # Additional methods for Capybara
    class Capybara
      DRIVERS = %w[poltergeist webkit selenium]

      # Register proxy drivers
      def self.register_drivers
        DRIVERS.each do |name|
          begin
            send("register_#{name.to_s}_driver")
          rescue LoadError
          end
        end
      end

      # Register poltergeist with a proxy
      # @param options [Hash] the options to pass to the driver
      def self.register_poltergeist_driver(options = {})
        require 'capybara/poltergeist'
        ::Capybara.register_driver :poltergeist_billy do |app|
          options = options.merge(
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
        require 'capybara/webkit'
        ::Capybara.register_driver :webkit_billy do |app|
          options = options.merge(
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
      # @param profile [Capybara::WebDriver::Firefox::Options] the options
      # to pass to the driver
      def self.register_selenium_firefox(options = nil)
        require 'selenium/webdriver'
        ::Capybara.register_driver :selenium_billy do |app|
          options ||= Selenium::WebDriver::Firefox::Options.new
          profile = options.profile || Selenium::WebDriver::Firefox::Profile.new
          profile.assume_untrusted_certificate_issuer = false
          profile.proxy = Selenium::WebDriver::Proxy.new(
            http: "#{Billy.proxy.host}:#{Billy.proxy.port}",
            ssl: "#{Billy.proxy.host}:#{Billy.proxy.port}"
          )
          ::Capybara::Selenium::Driver.new(app, options: options)
        end
      end

      # Register chrome with a proxy
      # @param options [Capybara::WebDriver::Chrome::Options] the options
      # to pass to the driver
      def self.register_selenium_chrome(options = nil)
        require 'selenium/webdriver'
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
