require 'billy'
require 'watir-webdriver'

module Billy
  module Browsers
    class Watir < ::Watir::Browser

      def initialize(name, args = {})
        @defaults = {
          chrome: {
            switches: %W[--proxy-server=#{Billy.config.proxy_host}:#{Billy.config.proxy_port}]
          },
          phantomjs: {
            args: %W[--proxy=#{Billy.config.proxy_host}:#{Billy.config.proxy_port}]
          },
          firefox: {
            profile: Selenium::WebDriver::Firefox::Profile.new,
            proxy: Selenium::WebDriver::Proxy.new(
              http: "#{Billy.config.proxy_host}:#{Billy.config.proxy_port}",
              ssl: "#{Billy.config.proxy_host}:#{Billy.config.proxy_port}"
            )
          }
        }

        args = case name
          when :chrome then configure_chrome(args)
          when :phantomjs then configure_phantomjs(args)
          else configure_firefox(args)
        end
        super
      end

      private

      def configure_chrome(args)
        args[:switches] ||= []
        args[:switches] += @defaults[:chrome][:switches]
        args
      end

      def configure_phantomjs(args)
        args[:args] ||= []
        args[:args] += @defaults[:phantomjs][:args]
        args
      end

      def configure_firefox(args)
        args[:profile] ||= @defaults[:firefox][:profile]
        args[:profile].proxy = @defaults[:firefox][:proxy]
        args
      end

    end
  end
end
