require 'resolv'
require 'uri'
require 'yaml'

module Billy
  class Cache
    def initialize
      reset
      load_dir
    end

    def cacheable?(url, headers)
      if Billy.config.cache
        host = URI(url).host
        Billy.log(:info, Billy.config.whitelist)
        !Billy.config.whitelist.include?(host)
        # TODO test headers for cacheability
      end
    end

    def cached?(url)
      !@cache[url].nil?
    end

    def fetch(url)
      @cache[url]
    end

    def store(url, status, headers, content)
      cached = {
        :url => url,
        :status => status,
        :headers => headers,
        :content => content
      }

      @cache[url] = cached

      key = URI(url).host+'_'+Digest::SHA1.hexdigest(url)
      File.open("spec/cache/"+key+".yml", 'w') { |f| f.write(cached.to_yaml) }
    end

    def reset
      @cache = {}
    end

    def load_dir
      Dir.glob("spec/cache/*.yml") { |filename|
        data = begin
                 YAML.load(File.open(filename))
               rescue ArgumentError => e
                 puts "Could not parse YAML: #{e.message}"
               end
        @cache[data["url"]] = data
      }
    end
  end
end
