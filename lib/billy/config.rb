require 'logger'

module Billy
  class Config
    attr_accessor :logger

    def initialize
      @logger = defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
    end
  end

  def self.configure
    yield config if block_given?
    config
  end

  def self.log(*args)
    unless config.logger.nil?
      config.logger.send(*args)
    end
  end

  private

  def self.config
    @config ||= Config.new
  end
end
