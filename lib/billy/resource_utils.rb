require 'uri'
require 'json'

module Billy
  module ResourceUtils

    def parse_anchor(url)
      anchor_split = url.split('#')
      anchor_split.length > 1 ? anchor_split[1] : nil
    end

    def url_formatted(url, include_params=false)
      url = URI(url)
      url_anchor = parse_anchor(url.to_s)
      format = url.scheme+'://'+url.host+url.path
      if include_params
        format += '?'+url.query if url.query
        format += '#'+url_anchor if url_anchor
      end
      format
    end

    def json?(value)
      JSON.parse(value)
    rescue
      false
    end

    def sorted_hash(hash, &block)
      Hash[
          hash.each do |k,v|
            hash[k] = sorted_hash(v, &block) if v.class == Hash
            hash[k] = v.collect {|a| sorted_hash(a, &block)} if v.class == Array
          end.sort(&block)
      ]
    end

    def sorted_json(json_str)
      sorted_hash(JSON.parse(json_str, symbolize_names: true)).to_json
    end
  end
end