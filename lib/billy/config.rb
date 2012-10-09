module Billy
  class Config
    attr_accessor :logger

    def initialize
      @logger = nil
    end
  end

  def self.configure
    @config ||= Config.new
    yield @config if block_given?
    @config
  end

  def self.log(*args)
    unless @config.logger.nil?
      @config.logger.send(*args)
    end
  end
end

