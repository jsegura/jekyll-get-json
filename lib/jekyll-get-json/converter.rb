require "jekyll"
require "uri"
require "net/http"
require "net/https"
require "json"
require "deep_merge"

module JekyllGetJson
  class GetJsonGenerator < Jekyll::Generator
    safe true
    priority :highest

    def generate(site)
      config = site.config["jekyll_get_json"]
      if !config
        warn "No config".yellow
        return
      end
      if !config.kind_of?(Array)
        config = [config]
      end

      config.each do |d|
        begin
          uri = URI(d["json"])
          user = d["user"]
          pass = d["pass"]
          bearer = d["bearer"]

          puts "Reading JSON from #{uri}"
          Net::HTTP.start(uri.host, uri.port,
                          :use_ssl => uri.scheme == "https",
                          :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
            req = Net::HTTP::Get.new uri.request_uri
            if user
              req.basic_auth user, pass
            end
            if bearer
              req["Authorization"] = "Bearer #{bearer}"
            end

            resp = http.request req # Net::HTTPResponse object

            if resp.code != "200"
              warn "Bad JSON response #{resp.code}: #{resp.message}"
              next
            end
            source = JSON.parse(resp.body)
            target = site.data[d["data"]]
            if target
              target.deep_merge(source)
            else
              site.data[d["data"]] = source
            end
          end
        rescue
          next
        end
      end
    end
  end
end
