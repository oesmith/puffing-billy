require 'resolv'
require 'addressable/uri'
require 'yaml'
require 'billy/json_utils'
require 'singleton'

module Billy
  class Cache
    include Singleton

    attr_reader :scope

    def initialize
      reset
    end

    def cached?(method, url, body)
      # Only log the key the first time it's looked up (in this method)
      key = key(method, url, body, true)
      !@cache[key].nil? || persisted?(key)
    end

    def persisted?(key)
      Billy.config.persist_cache && File.exist?(cache_file(key))
    end

    def fetch(method, url, body)
      key = key(method, url, body)
      @cache[key] || fetch_from_persistence(key)
    end

    def fetch_from_persistence(key)
      @cache[key] = YAML.load_file(cache_file(key)) if persisted?(key)
    rescue ArgumentError => e
      Billy.log :error, "Could not parse YAML: #{e.message}"
      nil
    end

    def store(key, _scope, method, url, request_headers, body, response_headers, status, content)
      cached = {
        scope: _scope,
        url: format_url(url),
        body: body,
        status: status,
        method: method,
        headers: response_headers,
        content: content
      }

      cached.merge!(request_headers: request_headers) if Billy.config.cache_request_headers

      @cache[key] = cached

      if Billy.config.persist_cache
        Dir.mkdir(Billy.config.cache_path) unless File.exist?(Billy.config.cache_path)

        begin
          File.open(cache_file(key), 'w') do |f|
            f.write(cached.to_yaml(Encoding: :Utf8))
          end
        rescue StandardError => e
          Billy.log :error, "Error storing cache file: #{e.message}"
        end
      end
    end

    def reset
      @cache = {}
    end

    def key(method, orig_url, body, log_key = false)
      if Billy.config.use_ignore_params
        ignore_params = Billy.config.ignore_params.include?(format_url(orig_url, true))
      else
        ignore_params = !Billy.config.allow_params.include?(format_url(orig_url, true))
      end
      merge_cached_response_key = _merge_cached_response_key(orig_url)
      url = Addressable::URI.parse(format_url(orig_url, ignore_params))
      key = if merge_cached_response_key
              method + '_' + Digest::SHA1.hexdigest(scope.to_s + merge_cached_response_key)
            else
              method + '_' + url.host + '_' + Digest::SHA1.hexdigest(scope.to_s + url.to_s)
            end
      body_msg = ''

      if Billy.config.cache_request_body_methods.include?(method) && !ignore_params && !merge_cached_response_key
        body_formatted = JSONUtils.json?(body.to_s) ? JSONUtils.sort_json(body.to_s) : body.to_s
        body_msg = " with body '#{body_formatted}'"
        key += '_' + Digest::SHA1.hexdigest(body_formatted)
      end

      Billy.log(:info, "puffing-billy: CACHE KEY for '#{orig_url}#{body_msg}' is '#{key}'") if log_key
      key
    end

    def format_url(url, ignore_params = false, dynamic_jsonp = Billy.config.dynamic_jsonp)
      url = Addressable::URI.parse(url)
      port_to_include = Billy.config.ignore_cache_port ? '' : ":#{url.port}"
      formatted_url = url.scheme + '://' + url.host + port_to_include + url.path

      return formatted_url if ignore_params

      if url.query
        query_string = if dynamic_jsonp
                         query_hash = Rack::Utils.parse_query(url.query)
                         Billy.config.dynamic_jsonp_keys.each { |k| query_hash.delete(k) }
                         Rack::Utils.build_query(query_hash)
                       else
                         url.query
                       end

        formatted_url += "?#{query_string}"
      end

      formatted_url += '#' + url.fragment if url.fragment

      formatted_url
    end

    def cache_file(key)
      file = File.join(Billy.config.cache_path, "#{key}.yml")

      if File.symlink? file
        file = File.readlink file
      end

      file
    end

    def scope_to(new_scope = nil)
      self.scope = new_scope
    end

    def with_scope(use_scope = nil, &block)
      fail ArgumentError, 'Expected a block but none was received.' if block.nil?
      original_scope = scope
      scope_to use_scope
      block.call
    ensure
      scope_to original_scope
    end

    def use_default_scope
      scope_to nil
    end

    private

    def _merge_cached_response_key(url)
      Billy.config.merge_cached_responses_whitelist.each do |disable_regex|
        if url =~ disable_regex
          return disable_regex.to_s # Use the stringified regex as the cache key if it matches
        end
      end
      nil
    end

    attr_writer :scope
  end
end
