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
        uri  = URI(url)
        host = uri.host
        port = uri.port
        !Billy.config.whitelist.include?(host) || !Billy.config.whitelist.include?("#{host}:#{port}")
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
          path = File.join(Billy.config.cache_path,
                           "#{key(method, url, body)}.yml")
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

      # Unique key based on anchor path instead of full url
      anchor_split = URI(url).to_s.split('#')
      anchor_path  = anchor_split.length > 1 ? anchor_split[1] : nil
      key = method+'_'+url.host+'_'+Digest::SHA1.hexdigest(anchor_path ? anchor_path : url.to_s)

      if method == 'post' and !Billy.config.ignore_params.include?(no_params)
        key += '_'+Digest::SHA1.hexdigest(body.to_s)
      end

      key
    end
  end
end
