require "jekyll"
require 'net/http'
require 'json'
require 'deep_merge'
require 'open-uri'


module JekyllGetJson
  class GetJsonGenerator < Jekyll::Generator
    safe true
    priority :highest

    def generate(site)

      config = site.config['jekyll_get_json']
      if !config
        warn "No config".yellow
        return
      end
      if !config.kind_of?(Array)
        config = [config]
      end

      config.each do |d|
        begin
          uri = URI(d['json'])
          req = Net::HTTP::Get.new(uri.request_uri)
          user = d['user']
          pass = d['pass']
          if user
            req.basic_auth user, pass
          end
          resp = Net::HTTP.start(uri.hostname, uri.port) {|http|
            http.request(req)
          }
          source = JSON.parse(resp)
          target = site.data[d['data']]
          if target
            target.deep_merge(source)
          else
            site.data[d['data']] = source
          end
        rescue
          next
        end
      end
    end
  end
end

