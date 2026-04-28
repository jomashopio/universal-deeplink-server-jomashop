require "uri"
require "kemal"
require "dotenv"

Dotenv.load if (Kemal.config.env == "development") && File.exists?(".env")
Dotenv.load(path: ".env.test") if Kemal.config.env == "test"

error_context = "Use the root path instead, i.e. `/?r=TARGET_URL_HERE`"

# Read static association files once at startup
AASA_CONTENT = File.read("apple-app-site-association")
ASSETLINKS_CONTENT = File.read("assetlinks.json")

get "/" do |env|
  begin
    redirect_param = env.params.query["r"]?

    # If no r parameter, redirect to DEFAULT_DESTINATION (only if set)
    unless redirect_param
      if default_destination = ENV["DEFAULT_DESTINATION"]?
        env.redirect default_destination
        next
      else
        raise "Missing redirect parameter"
      end
    end

    target_uri = URI.parse(redirect_param)

    # Check that it's a valid URL
    valid_uri = /https?/ =~ target_uri.scheme && target_uri.host
    raise "Invalid redirect URL" unless valid_uri

    # Normalize host logic (handle nil host which shouldn't happen due to valid_uri check but good for safety)
    if host = target_uri.host
      # Validate against whitelist if configured
      if whitelist_str = ENV["WHITELIST_DESTINATIONS"]?
        whitelist = whitelist_str.split(",").map { |h| h.strip }

        # Check if host is in whitelist
        is_whitelisted = whitelist.includes?(host) || (host.starts_with?("www.") && whitelist.includes?(host[4..-1]))

        # Also check if it matches DEFAULT_DESTINATION's host (implicit whitelist)
        if !is_whitelisted
           if default_dest = ENV["DEFAULT_DESTINATION"]?
             if default_uri = URI.parse(default_dest)
                if default_host = default_uri.host
                   is_whitelisted = (host == default_host)
                end
             end
           end
        end

        raise "Destination not allowed" unless is_whitelisted
      end
    end

    # Redirect (bounce back) requested URL
    env.redirect target_uri.to_s
  rescue udl_error
    render "src/views/fallback.ecr"
  end
end

get "/.well-known/apple-app-site-association" do |env|
  env.response.content_type = "application/json"
  AASA_CONTENT
end

get "/.well-known/assetlinks.json" do |env|
  env.response.content_type = "application/json"
  ASSETLINKS_CONTENT
end

get "/*" do |env|
  # If DEFAULT_DESTINATION is set, redirect to it + path; otherwise show fallback.
  if default_target = ENV["DEFAULT_DESTINATION"]?
    path = env.request.path
    final_url = default_target.rstrip("/") + "/" + path.lstrip("/")
    env.redirect final_url
  else
    udl_error = "Invalid path `#{env.request.path}` - #{error_context}"
    render "src/views/fallback.ecr"
  end
end

error 404 do
  udl_error = "Resource Not Found - #{error_context}"
  render "src/views/fallback.ecr"
end

serve_static false
Kemal.config.port = ENV.fetch("PORT", "3000").to_i
Kemal.run
