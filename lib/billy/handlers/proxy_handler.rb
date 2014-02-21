require 'billy/handlers/handler'
require 'eventmachine'

module Billy
  class ProxyHandler
    include Handler

    def handles_request?(method, url, headers, body)
      !disabled_request?(url)
    end

    def handle_request(method, url, headers, body)
      unless handles_request?(method, url, headers, body)
        req = EventMachine::HttpRequest.new(url)
        build_request_options(headers, body).tap do |opts|
          req = req.send(method.downcase, build_request_options(headers, body))
        end

        req.errback do
          return { :error => "Request failed: #{url}" }
        end

        req.callback do
          response = process_response(req)

          unless allowed_response_code?(response[:status])
            if Billy.config.non_successful_error_level == :error
              return { :error => "Request failed due to response status #{response[:status]} for '#{url}' which was not allowed." }
            else
              Billy.log(:warn, "puffing-billy: Received response status code #{response[:status]} for '#{url}'")
            end
          end

          if cacheable?(response[:headers], response[:status])
            CacheHandler.store(method.downcase, url, headers, body, response[:headers], response[:status], response[:content])
          end

          Billy.log(:info, "puffing-billy: PROXY #{method} succeeded for '#{url}'")
          return response
        end
      end

      nil
    end

    private

    def build_request_options(headers, body)
      headers = Hash[headers.map { |k,v| [k.downcase, v] }]
      headers.delete('accept-encoding')

      req_opts = {
          :redirects => 0,
          :keepalive => false,
          :head => headers,
          :ssl => { :verify => false }
      }
      req_opts[:body] = body if body
      req_opts
    end

    def process_response(req)
      response = {
          :status  => req.response_header.status,
          :headers => req.response_header.raw,
          :content => req.response.force_encoding('BINARY') }
      response[:headers].merge!('Connection' => 'close')
      response[:headers].delete('Transfer-Encoding')
      response
    end

    def disabled_request?(url)
      uri = URI(url)
      # In isolated environments, you may want to stop the request from happening
      # or else you get "getaddrinfo: Name or service not known" errors
      if Billy.config.non_whitelisted_requests_disabled
        blacklisted_path?(uri.path) || !whitelisted_url?(uri)
      end
    end

    def allowed_response_code?(status)
      log_level = successful_status?(status) ? :info : Billy.config.non_successful_error_level
      log_message = "puffing-billy: Received response status code #{status} for #{@url}"
      Billy.log(log_level, log_message)
      # FIXME: We can't close the connection here:
      if log_level == :error
        #close_connection
        raise log_message
      end
    end

    def cacheable?(headers, status)
      if Billy.config.cache
        url = URI(@url)
        # Cache the responses if they aren't whitelisted host[:port]s but always cache blacklisted paths on any hosts
        cacheable_headers?(headers) && cacheable_status?(status) && (!whitelisted_url?(url) || blacklisted_path?(url.path))
      end
    end

    def whitelisted_host?(host)
      Billy.config.whitelist.include?(host)
    end

    def whitelisted_url?(url)
      whitelisted_host?(url.host) || whitelisted_host?("#{url.host}:#{url.port}")
    end

    def blacklisted_path?(path)
      Billy.config.path_blacklist.index{|bl| path.include?(bl)}
    end

    def successful_status?(status)
      (200..299).include?(status) || status == 304
    end

    def cacheable_headers?(headers)
      #TODO: test headers for cacheability (ie. Cache-Control: no-cache)
      true
    end

    def cacheable_status?(status)
      Billy.config.non_successful_cache_disabled ? successful_status?(status) : true
    end
  end
end