require 'billy'

module Billy
  module Browsers
    class Capybara

      DRIVERS = {
        poltergeist: 'capybara/poltergeist',
        webkit: 'capybara/webkit',
        selenium: 'selenium/webdriver',
        apparition: 'capybara/apparition',
        cuprite: 'capybara/cuprite'
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
          capabilities = [
            build_selenium_options_for_firefox,
            Selenium::WebDriver::Remote::Capabilities.firefox(accept_insecure_certs: true)
          ]

          ::Capybara::Selenium::Driver.new(app, capabilities: capabilities)
        end

        ::Capybara.register_driver :selenium_headless_billy do |app|
          options = build_selenium_options_for_firefox.tap do |opts|
            opts.add_argument '-headless'
          end
          capabilities = [
            options,
            Selenium::WebDriver::Remote::Capabilities.firefox(accept_insecure_certs: true)
          ]

          ::Capybara::Selenium::Driver.new(app, capabilities: capabilities)
        end

        ::Capybara.register_driver :selenium_chrome_billy do |app|
          options = Selenium::WebDriver::Chrome::Options.new
          options.add_argument('--ignore-certificate-errors')
          options.add_argument("--proxy-server=#{Billy.proxy.host}:#{Billy.proxy.port}")

          ::Capybara::Selenium::Driver.new(
            app,
            browser: :chrome,
            capabilities: options,
            clear_local_storage: true,
            clear_session_storage: true
          )
        end

        ::Capybara.register_driver :selenium_chrome_headless_billy do |app|
            options = Selenium::WebDriver::Chrome::Options.new
            options.add_argument('--headless=new')
            options.add_argument('--enable-features=NetworkService,NetworkServiceInProcess')
            options.add_argument('--ignore-certificate-errors')
            options.add_argument("--proxy-server=#{Billy.proxy.host}:#{Billy.proxy.port}")
            options.add_argument('--disable-gpu') if Gem.win_platform?
            options.add_argument('--no-sandbox') if ENV['CI']

          ::Capybara::Selenium::Driver.new(
            app,
            browser: :chrome,
            capabilities: options,
            clear_local_storage: true,
            clear_session_storage: true
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

      def self.register_cuprite_driver
        driver_otions = {
          browser_options: {
            'ignore-certificate-errors' => nil
          }
        }.deep_merge(Billy.config.cuprite_options)

        ::Capybara.register_driver :cuprite_billy do |app|
          ::Capybara::Cuprite::Driver.new(app, **driver_otions).tap do |driver|
            driver.set_proxy(Billy.proxy.host, Billy.proxy.port)
          end
        end
      end

      def self.build_selenium_options_for_firefox
        profile = Selenium::WebDriver::Firefox::Profile.new.tap do |prof|
          prof.proxy = Selenium::WebDriver::Proxy.new(
            http: "#{Billy.proxy.host}:#{Billy.proxy.port}",
            ssl: "#{Billy.proxy.host}:#{Billy.proxy.port}")
        end

        Selenium::WebDriver::Firefox::Options.new(profile: profile)
      end
    end
  end
end
