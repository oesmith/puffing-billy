require 'billy'
require 'watir'

module Billy
  module Browsers
    class Watir < ::Watir::Browser

      def initialize(name, args = {})
        args = case name
          when :chrome then configure_chrome(args)
          when :phantomjs then configure_phantomjs(args)
          when :firefox then configure_firefox(args)
          else
            raise NameError, "Invalid browser driver specified. (Expected: :chrome, :phantomjs, :firefox)"
        end
        super
      end

      private

      def configure_chrome(args)
        args[:headless] = true
        args[:switches] ||= []
        args[:switches] += %W[--proxy-server=#{Billy.proxy.host}:#{Billy.proxy.port}]
        args
      end

      def configure_phantomjs(args)
        args[:driver_opts] ||= {}
        args[:driver_opts][:args] ||= []
        args[:driver_opts][:args] += %W[--proxy=#{Billy.proxy.host}:#{Billy.proxy.port}]
        args
      end

      def configure_firefox(args)
        args[:profile] ||= Selenium::WebDriver::Firefox::Profile.new
        args[:profile].proxy = Selenium::WebDriver::Proxy.new(
          http: "#{Billy.proxy.host}:#{Billy.proxy.port}",
          ssl: "#{Billy.proxy.host}:#{Billy.proxy.port}"
        )
        args
      end

    end
  end
end
