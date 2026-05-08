require "kemal"
require "dotenv"

Dotenv.load if (Kemal.config.env == "development") && File.exists?(".env")
Dotenv.load(path: ".env.test") if Kemal.config.env == "test"

# Read static association files once at startup
AASA_CONTENT = File.read("apple-app-site-association")
ASSETLINKS_CONTENT = File.read("assetlinks.json")

get "/.well-known/apple-app-site-association" do |env|
  env.response.content_type = "application/json"
  AASA_CONTENT
end

get "/.well-known/assetlinks.json" do |env|
  env.response.content_type = "application/json"
  ASSETLINKS_CONTENT
end

# ── Smart App Store Link ──
# Detects iOS/Android via client-side UA and redirects to the correct store.
# Desktop/unknown falls back to the web landing page.
get "/home" do |env|
  render "src/views/smartlink.ecr"
end

# ── In-App Store Trigger ──
# Detects iOS/Android via client-side UA and redirects to the correct store.
# Desktop/unknown falls back to the web landing page.
get "/app/" do |env|
  render "src/views/appstore.ecr"
end

# ── In-App Upgrade Trigger ──
# Server-side 302 to break out of the app's webview.
# AASA excludes this path so iOS doesn't intercept it.
get "/app-upgrade/" do |env|
  env.redirect "https://apps.apple.com/us/app/jomashop-designer-shopping/id6444218472"
end

get "/" do |env|
  if default_target = ENV["DEFAULT_DESTINATION"]?
    env.redirect default_target.rstrip("/") + "/"
  else
    udl_error = "DEFAULT_DESTINATION not configured"
    render "src/views/fallback.ecr"
  end
end

get "/*" do |env|
  if default_target = ENV["DEFAULT_DESTINATION"]?
    path = env.request.path
    final_url = default_target.rstrip("/") + "/" + path.lstrip("/")
    env.redirect final_url
  else
    udl_error = "DEFAULT_DESTINATION not configured"
    render "src/views/fallback.ecr"
  end
end

error 404 do
  udl_error = "Resource Not Found"
  render "src/views/fallback.ecr"
end

serve_static false
Kemal.config.port = ENV.fetch("PORT", "3000").to_i
Kemal.run
