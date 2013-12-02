require 'uri'
require 'json'

module Billy
  module JSONUtils

    def json?(value)
      !!JSON.parse(value)
    rescue JSON::ParserError, TypeError
      false
    end

    # Recursively sorts the key/value pairs of all hashes within the given
    #   data structure while preserving the order of arrays.
    def sort_hash_keys(data)
      return data unless data.is_a?(Hash) || data.is_a?(Array)
      if data.is_a? Hash
        data.keys.sort.reduce({}) do |seed, key|
          seed[key] = sort_hash_keys(data[key])
          seed
        end
      else
        data.map do |element|
          sort_hash_keys(element)
        end
      end
    end

    # Recursively sorts the name/value pairs of JSON objects. For instance,
    #   sort_json('{"b" : "2", "a" : "1"}') == sort_json('{"a" : "1", "b" : "2"}')
    #   Per http://json.org/, "An object is an unordered set of name/value pairs"
    #   and "An array is an ordered collection of values". So, we can sort the
    #   name/value pairs by name (key), but we must preserve the order of an array.
    #   Processing JSON in this way enables a consistent SHA to be derived from
    #   JSON payloads which have the same name/value pairs, but different orders.
    def sort_json(json_str)
      sort_hash_keys(JSON.parse(json_str, symbolize_names: true)).to_json
    end
  end
end