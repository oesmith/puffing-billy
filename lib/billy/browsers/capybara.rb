require 'billy'

module Billy
  module Browsers
    class Capybara

      DRIVERS = {
        poltergeist: 'capybara/poltergeist',
        webkit: 'capybara/webkit',
        selenium: 'selenium/webdriver',
        apparition: 'capybara/apparition'
      }

      def self.register_drivers
        DRIVERS.each do |name, driver|
          begin
            require driver
            send("register_#{name}_driver")
          rescue LoadError
          end
        end
      end

      private

      def self.register_poltergeist_driver
        ::Capybara.register_driver :poltergeist_billy do |app|
          options = {
            phantomjs_options: [
              '--ignore-ssl-errors=yes',
              "--proxy=#{Billy.proxy.host}:#{Billy.proxy.port}"
            ]
          }
          ::Capybara::Poltergeist::Driver.new(app, options)
        end
      end

      def self.register_webkit_driver
        ::Capybara.register_driver :webkit_billy do |app|
          options = {
            ignore_ssl_errors: true,
            proxy: {host: Billy.proxy.host, port: Billy.proxy.port}
          }
          ::Capybara::Webkit::Driver.new(app, ::Capybara::Webkit::Configuration.to_hash.merge(options))
        end
      end

      def self.register_selenium_driver
        ::Capybara.register_driver :selenium_billy do |app|
          profile = Selenium::WebDriver::Firefox::Profile.new.tap do |prof|
            prof.assume_untrusted_certificate_issuer = false
            prof.proxy = Selenium::WebDriver::Proxy.new(
              http: "#{Billy.proxy.host}:#{Billy.proxy.port}",
              ssl: "#{Billy.proxy.host}:#{Billy.proxy.port}")
          end
          options = Selenium::WebDriver::Firefox::Options.new(profile: profile)
          
          ::Capybara::Selenium::Driver.new(app, options: options)
        end

        ::Capybara.register_driver :selenium_chrome_billy do |app|
          options = Selenium::WebDriver::Chrome::Options.new
          options.add_argument("--proxy-server=#{Billy.proxy.host}:#{Billy.proxy.port}")

          ::Capybara::Selenium::Driver.new(
            app, browser: :chrome,
            options: options
          )
        end
        
        ::Capybara.register_driver :selenium_chrome_headless_billy do |app|
          options = Selenium::WebDriver::Chrome::Options.new(args: %w[headless disable-gpu no-sandbox
                                                                      enable-features=NetworkService,NetworkServiceInProcess])
          options.add_argument("--proxy-server=#{Billy.proxy.host}:#{Billy.proxy.port}")

          ::Capybara::Selenium::Driver.new(
            app, browser: :chrome,
            options: options
          )
        end
      end

      def self.register_apparition_driver
        ::Capybara.register_driver :apparition_billy do |app|
          ::Capybara::Apparition::Driver.new(app, ignore_https_errors: true).tap do |driver|
            driver.set_proxy(Billy.proxy.host, Billy.proxy.port)
          end
        end
      end
    end
  end
end
