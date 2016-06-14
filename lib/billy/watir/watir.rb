require 'billy'

module Billy
  def self.browser(name, args = {})
    if(name === :chrome)
      switches = args[:switches]

      if switches.nil?
        switches = @settings[:chrome][:switches]
      else
        switches.push(*@settings[:chrome][:switches])
      end

      @browser = Watir::Browser.new :chrome, **args
    else
      profile = args[:profile]

      if profile.nil?
        profile = @settings[:firefox][:profile]
      end
      profile.proxy = @settings[:firefox][:proxy]

      args[:profile] = profile

      @browser = Watir::Browser.new :firefox, **args
    end
    @browser
  end

  def self.register_drivers
    ['watir-webdriver'].each do |d|
      begin
        require d
      rescue LoadError
      end
    end

    @settings = {}

    if defined?(Selenium::WebDriver)
      @settings[:firefox] = {
        profile: Selenium::WebDriver::Firefox::Profile.new,
        proxy: Selenium::WebDriver::Proxy.new(
          http: "#{Billy.proxy.host}:#{Billy.proxy.port}",
          ssl: "#{Billy.proxy.host}:#{Billy.proxy.port}"
        )
      }

      @settings[:chrome] = {
        switches: %W[--proxy-server=#{Billy.proxy.host}:#{Billy.proxy.port}]
      }
    end
  end

  private

  def self.settings(name)
    @settings[name]
  end
end
