require 'resolv'
require 'uri'
require 'yaml'

module Billy
  class Cache
    attr_reader :scope

    def initialize
      reset
      load_dir
    end

    def cacheable?(url, headers)
      if Billy.config.cache
        url = URI(url)
        # Cache the responses if they aren't whitelisted host[:port]s but always cache /api on any hosts
        !Billy.config.whitelist.include?(url.host) && !Billy.config.whitelist.include?("#{url.host}:#{url.port}") || url.path.include?('/api')
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
        :scope => scope,
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
      url          = URI(url)
      anchor_split = url.to_s.split('#')
      url_anchor   = anchor_split.length > 1 ? anchor_split[1] : nil
      # Both of these remove the port from the url
      no_params    = url.scheme+'://'+url.host+url.path
      with_params  = no_params
      with_params += '?'+url.query if url.query
      with_params += '#'+url_anchor if url_anchor

      if Billy.config.ignore_params.include?(no_params)
        url_to_use = URI(no_params)
      else
        url_to_use = URI(with_params)
      end
      key = method+'_'+url.host+'_'+Digest::SHA1.hexdigest(scope.to_s + url_to_use.to_s)

      if method == 'post' and !Billy.config.ignore_params.include?(no_params)
        key += '_'+Digest::SHA1.hexdigest(body.to_s)
      end

      key
    end

    def scope_to(new_scope = nil)
      self.scope = new_scope
    end

    def with_scope(use_scope = nil, &block)
      raise ArgumentError, 'Expected a block but none was received.' if block.nil?
      original_scope = scope
      scope_to use_scope
      block.call()
    ensure
      scope_to original_scope
    end

    def use_default_scope
      scope_to nil
    end

    private

    attr_writer :scope
  end
end
