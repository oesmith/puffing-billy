require 'uri'
require 'json'

module Billy
  module ResourceUtils

    def format_url(url, include_params=false)
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

    # This method sorts JSON data, recursively and consistently to enable
    #   consistent hashing of the JSON data string. It will recursively sort
    #   data contained in nested JSON Hash and Array data structures.
    def self.sort_json_data(data)
      return data if !data.is_a? Enumerable

      result = if data.is_a?(Hash)
          data.collect { |k,v| [k,sort_json_data(v)] }
        else
          data.collect { |item| sort_json_data(item) }
        end.group_by(&:class).values.map do |values|
          # Actually sort the data
          values.sort do |v1,v2|
            r = v1 <=> v2

            # Sometimes objects cannot be compared using the default <=> operator,
            #   so we use a hash digest of the string value of the object for comparison:
            [-1,0,1].include?(r) ? r : v1.to_s <=> v2.to_s
          end
        end.inject(:+)

      data.is_a?(Hash) ? Hash[result] : result
    end

    def sort_json(json_str)
      ResourceUtils.sort_json_data(JSON.parse(json_str, symbolize_names: true)).to_json
    end
  end
end