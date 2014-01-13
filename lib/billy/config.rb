require 'logger'
require 'tmpdir'

module Billy
  class Config
    DEFAULT_WHITELIST = ['127.0.0.1', 'localhost']

    attr_accessor :logger, :cache, :whitelist, :path_blacklist, :ignore_params, :persist_cache,
                  :ignore_cache_port, :non_successful_cache_disabled, :non_successful_error_level,
                  :non_whitelisted_requests_disabled, :cache_path

    def initialize
      @logger = defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
      reset
    end

    def reset
      @cache = true
      @whitelist = DEFAULT_WHITELIST
      @path_blacklist = []
      @ignore_params = []
      @persist_cache = false
      @ignore_cache_port = true
      @non_successful_cache_disabled = false
      @non_successful_error_level = :warn
      @non_whitelisted_requests_disabled = false
      @cache_path = File.join(Dir.tmpdir, 'puffing-billy')
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
