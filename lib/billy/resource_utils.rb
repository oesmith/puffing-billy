require 'uri'
require 'json'

module Billy
  module ResourceUtils

    def url_formatter(url, include_params=false)
      url = URI(url)
      url_fragment = url.fragment
      formatted_url = url.scheme+'://'+url.host+url.path
      if include_params
        formatted_url += '?'+url.query if url.query
        formatted_url += '#'+url_fragment if url_fragment
      end
      formatted_url
    end

    def json?(value)
      JSON.parse(value)
    rescue
      false
    end

    def sort_hash(hash, &block)
      Hash[
          hash.each do |k,v|
            hash[k] = sort_hash(v, &block) if v.class == Hash
            hash[k] = v.collect {|a| sort_hash(a, &block)} if v.class == Array
          end.sort(&block)
      ]
    end

    def sorted_json(json_str)
      sort_hash(JSON.parse(json_str, symbolize_names: true)).to_json
    end
  end
end