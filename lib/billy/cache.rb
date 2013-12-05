require 'resolv'
require 'uri'
require 'yaml'
require 'billy/json_utils'

module Billy
  class Cache
    attr_reader :scope

    def initialize
      reset
    end

    def cacheable?(url, headers)
      if Billy.config.cache
        url = URI(url)
        # Cache the responses if they aren't whitelisted host[:port]s but always cache blacklisted paths on any hosts
        !Billy.config.whitelist.include?(url.host) && !Billy.config.whitelist.include?("#{url.host}:#{url.port}") || Billy.config.path_blacklist.index{|bl| url.path.include?(bl)}
        # TODO test headers for cacheability
      end
    end

    def cached?(method, url, body)
      key = key(method, url, body)
      !@cache[key].nil? or persisted?(key)
    end

    def persisted?(key)
      Billy.config.persist_cache and File.exists?(cache_file(key))
    end

    def fetch(method, url, body)
      key = key(method, url, body)
      @cache[key] or fetch_from_persistence(key)
    end

    def fetch_from_persistence(key)
      begin
        @cache[key] = YAML.load(File.open(cache_file(key))) if persisted?(key)
      rescue ArgumentError => e
        puts "Could not parse YAML: #{e.message}"
        nil
      end
    end

    def store(method, url, body, status, headers, content)
      cached = {
        :scope => scope,
        :url => format_url(url),
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
          File.open(cache_file(key), 'w') do |f|
            f.write(cached.to_yaml(:Encoding => :Utf8))
          end
        rescue StandardError => e
        end
      end
    end

    def reset
      @cache = {}
    end

    def key(method, url, body)
      ignore_params = Billy.config.ignore_params.include?(format_url(url, true))
      url = URI(format_url(url, ignore_params))
      key = method+'_'+url.host+'_'+Digest::SHA1.hexdigest(scope.to_s + url.to_s)

      if method == 'post' and !ignore_params
        body_formatted = JSONUtils::json?(body.to_s) ? JSONUtils::sort_json(body.to_s) : body.to_s
        key += '_'+Digest::SHA1.hexdigest(body_formatted)
      end

      key
    end

    def format_url(url, ignore_params=false)
      url = URI(url)
      port_to_include = Billy.config.ignore_port ? '' : ":#{url.port}"
      formatted_url = url.scheme+'://'+url.host+port_to_include+url.path
      unless ignore_params
        formatted_url += '?'+url.query if url.query
        formatted_url += '#'+url.fragment if url.fragment
      end
      formatted_url
    end

    def cache_file(key)
      File.join(Billy.config.cache_path, "#{key}.yml")
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
