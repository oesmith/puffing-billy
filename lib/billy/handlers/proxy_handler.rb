require 'billy/handlers/handler'
require 'addressable/uri'
require 'eventmachine'
require 'em-synchrony/em-http'

module Billy
  class ProxyHandler
    include Handler

    def handles_request?(_method, url, _headers, _body)
      !disabled_request?(url)
    end

    def handle_request(method, url, headers, body)
      if handles_request?(method, url, headers, body)
        req = EventMachine::HttpRequest.new(url,
                                            inactivity_timeout: Billy.config.proxied_request_inactivity_timeout,
                                            connect_timeout: Billy.config.proxied_request_connect_timeout)

        req = req.send(method.downcase, build_request_options(headers, body))

        if req.error
          return { error: "Request to #{url} failed with error: #{req.error}" }
        end

        if req.response
          response = process_response(req)

          unless allowed_response_code?(response[:status])
            if Billy.config.non_successful_error_level == :error
              return { error: "Request failed due to response status #{response[:status]} for '#{url}' which was not allowed." }
            else
              Billy.log(:warn, "puffing-billy: Received response status code #{response[:status]} for '#{url}'")
            end
          end

          if cacheable?(url, response[:headers], response[:status])
            Billy::Cache.instance.store(method.downcase, url, headers, body, response[:headers], response[:status], response[:content])
          end

          Billy.log(:info, "puffing-billy: PROXY #{method} succeeded for '#{url}'")
          return response
        end
      end
      nil
    end

    private

    def build_request_options(headers, body)
      headers = Hash[headers.map { |k, v| [k.downcase, v] }]
      headers.delete('accept-encoding')

      req_opts = {
        redirects: 0,
        keepalive: false,
        head: headers,
        ssl: { verify: false }
      }
      req_opts[:body] = body if body
      req_opts
    end

    def process_response(req)
      response = {
        status: req.response_header.status,
        headers: req.response_header.raw,
        content: req.response.force_encoding('BINARY') }
      response[:headers].merge!('Connection' => 'close')
      response[:headers].delete('Transfer-Encoding')
      response
    end

    def disabled_request?(url)
      return false unless Billy.config.non_whitelisted_requests_disabled

      uri = Addressable::URI.parse(url)
      # In isolated environments, you may want to stop the request from happening
      # or else you get "getaddrinfo: Name or service not known" errors
      blacklisted_path?(uri.path) || !whitelisted_url?(uri)
    end

    def allowed_response_code?(status)
      successful_status?(status)
    end

    def cacheable?(url, _headers, status)
      return false unless Billy.config.cache

      url = Addressable::URI.parse(url)
      # Cache the responses if they aren't whitelisted host[:port]s but always cache blacklisted paths on any hosts
      cacheable_status?(status) && (!whitelisted_url?(url) || blacklisted_path?(url.path))
    end

    def whitelisted_url?(url)
      Billy.config.whitelist.any? do |value|
        if value.is_a?(Regexp)
          url.to_s =~ value || url.omit(:port).to_s =~ value
        else
          value =~ /^#{url.host}(?::#{url.port})?$/
        end
      end
    end

    def blacklisted_path?(path)
      !Billy.config.path_blacklist.index { |bl| path.include?(bl) }.nil?
    end

    def successful_status?(status)
      (200..299).include?(status) || status == 304
    end

    def cacheable_status?(status)
      Billy.config.non_successful_cache_disabled ? successful_status?(status) : true
    end
  end
end
