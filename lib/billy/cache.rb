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

    def cached?(method, url)
      !@cache[key(method, url)].nil?
    end

    def fetch(method, url)
      @cache[key(method, url)]
    end

    def store(method, url, status, headers, content)
      cached = {
        :url => url,
        :status => status,
        :method => method,
        :headers => headers,
        :content => content
      }

      @cache[key(method, url)] = cached

      File.open("spec/cache/"+key(method, url)+".yml", 'w') {
        |f| f.write(cached.to_yaml(:Encoding => :Utf8))
      }
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

        @cache[key(data[:method], data[:url])] = data
      }
    end

    def key(method, url)
      url = URI(url)
      no_params = url.scheme+'://'+url.host+url.path

      if Billy.config.ignore_params.include?(no_params)
        url = no_params
      else
        url = url.to_s
      end

      method+'_'+URI(url).host+'_'+Digest::SHA1.hexdigest(url)
    end
  end
end
