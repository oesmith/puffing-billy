require 'billy'
require 'watir-webdriver'

module Billy
  module Browsers
    class Watir < ::Watir::Browser

      DEFAULTS = {
        chrome: {
          switches: %W[--proxy-server=#{Billy.proxy.host}:#{Billy.proxy.port}]
        },
        phantomjs: {
          args: %W[--proxy=#{Billy.proxy.host}:#{Billy.proxy.port}]
        },
        firefox: {
          profile: Selenium::WebDriver::Firefox::Profile.new,
          proxy: Selenium::WebDriver::Proxy.new(
            http: "#{Billy.proxy.host}:#{Billy.proxy.port}",
            ssl: "#{Billy.proxy.host}:#{Billy.proxy.port}"
          )
        }
      }

      def initialize(name, args = {})
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
        args[:switches] += DEFAULTS[:chrome][:switches]
        args
      end

      def configure_phantomjs(args)
        args[:args] ||= []
        args[:args] += DEFAULTS[:phantomjs][:args]
        args
      end

      def configure_firefox(args)
        args[:profile] ||= DEFAULTS[:firefox][:profile]
        args[:profile].proxy = DEFAULTS[:firefox][:proxy]
        args
      end

    end
  end
end
