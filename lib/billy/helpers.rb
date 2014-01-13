require 'uri'

module Billy
  class Helpers

    def self.format_url(url, ignore_params=false)
      url = URI(url)
      port_to_include = Billy.config.ignore_cache_port ? '' : ":#{url.port}"
      formatted_url = url.scheme+'://'+url.host+port_to_include+url.path
      unless ignore_params
        formatted_url += '?'+url.query if url.query
        formatted_url += '#'+url.fragment if url.fragment
      end
      formatted_url
    end

 private

    def self.whitelisted_host?(host)
      Billy.config.whitelist.include?(host)
    end

  end
end
