require 'logger'
require 'tmpdir'

module Billy
  class Config
    DEFAULT_WHITELIST = ['127.0.0.1', 'localhost']

    attr_accessor :logger, :cache, :whitelist, :ignore_params, :persist_cache, :cache_path

    def initialize
      @logger = defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
      reset
    end

    def reset
      @cache = true
      @whitelist = DEFAULT_WHITELIST
      @ignore_params = []
      @persist_cache = false
      @cache_path = Dir.tmpdir
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
