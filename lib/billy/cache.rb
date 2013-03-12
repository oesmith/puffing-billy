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

    def cached?(method, url, body)
      !@cache[key(method, url, body)].nil?
    end

    def fetch(method, url, body)
      @cache[key(method, url, body)]
    end

    def store(method, url, body, status, headers, content)
      cached = {
        :url => url,
        :body => body,
        :status => status,
        :method => method,
        :headers => headers,
        :content => content
      }

      @cache[key(method, url, body)] = cached

      if Billy.config.persist_cache
        Dir.mkdir(Billy.config.cache_path) unless File.exists?(Billy.config.cache_path)

        begin
          File.open(Billy.config.cache_path+key(method, url, body)+".yml", 'w') {
            |f| f.write(cached.to_yaml(:Encoding => :Utf8))
          }
        rescue StandardError => e
        end
      end
    end

    def reset
      @cache = {}
    end

    def load_dir
      if Billy.config.persist_cache
        Dir.glob(Billy.config.cache_path+"*.yml") { |filename|
          data = begin
                   YAML.load(File.open(filename))
                 rescue ArgumentError => e
                   puts "Could not parse YAML: #{e.message}"
                 end

          @cache[key(data[:method], data[:url], data[:body])] = data
        }
      end
    end

    def key(method, url, body)
      url = URI(url)
      no_params = url.scheme+'://'+url.host+url.path

      if Billy.config.ignore_params.include?(no_params)
        url = URI(no_params)
      end

      key = method+'_'+url.host+'_'+Digest::SHA1.hexdigest(url.to_s)

      if method == 'post' and !Billy.config.ignore_params.include?(no_params)
        key += '_'+Digest::SHA1.hexdigest(body.to_s)
      end

      key
    end
  end
end
