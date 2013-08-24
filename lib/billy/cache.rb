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
        !Billy.config.whitelist.include?(host)
        # TODO test headers for cacheability
      end
    end

    def cached?(method, url, body)
      key = key(method, url, body)
      !@cache[key].nil? or persisted?(key)
    end

    def persisted?(key)
      Billy.config.persist_cache and File.exists?(File.join(Billy.config.cache_path, "#{key}.yml"))
    end

    def fetch(method, url, body)
      key = key(method, url, body)
      @cache[key] or fetch_from_persistence(key)
    end

    def fetch_from_persistence(key)
      if Billy.config.persist_cache and Billy.config.cache_path
        cache_file = File.join(Billy.config.cache_path, "#{key}.yml")
        YAML.load(File.open(cache_file))
      end
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

      key = key(method, url, body)
      @cache[key] = cached

      if Billy.config.persist_cache
        Dir.mkdir(Billy.config.cache_path) unless File.exists?(Billy.config.cache_path)

        begin
          path = File.join(Billy.config.cache_path, "#{key}.yml")
          File.open(path, 'w') do |f|
            f.write(cached.to_yaml(:Encoding => :Utf8))
          end
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
