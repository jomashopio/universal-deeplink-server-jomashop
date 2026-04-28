require "./spec_helper"

def with_default_destination(value)
  original = ENV["DEFAULT_DESTINATION"]?
  ENV["DEFAULT_DESTINATION"] = value
  yield
ensure
  if original
    ENV["DEFAULT_DESTINATION"] = original
  else
    ENV.delete("DEFAULT_DESTINATION")
  end
end

def without_default_destination
  original = ENV["DEFAULT_DESTINATION"]?
  ENV.delete("DEFAULT_DESTINATION")
  yield
ensure
  ENV["DEFAULT_DESTINATION"] = original if original
end

def with_whitelist_destinations(value)
  original = ENV["WHITELIST_DESTINATIONS"]?
  ENV["WHITELIST_DESTINATIONS"] = value
  yield
ensure
  if original
    ENV["WHITELIST_DESTINATIONS"] = original
  else
    ENV.delete("WHITELIST_DESTINATIONS")
  end
end

def without_whitelist_destinations
  original = ENV["WHITELIST_DESTINATIONS"]?
  ENV.delete("WHITELIST_DESTINATIONS")
  yield
ensure
  ENV["WHITELIST_DESTINATIONS"] = original if original
end

describe "UDL Server" do
  context "success" do
    it "redirects to the Target URI parameter if valid" do
      without_whitelist_destinations do
        target_url = "https://fdo.cr/about"
        get "/?r=#{target_url}"

        response.status_code.should eq(302)
        response.headers["Location"].should eq(target_url)

        target_url = "http://fdo.cr/about"
        get "/?r=#{target_url}"

        response.status_code.should eq(302)
        response.headers["Location"].should eq(target_url)
      end
    end

    it "redirects to the Target URI parameter if host is allowed by WHITELIST_DESTINATIONS" do
      with_whitelist_destinations("fdo.cr,example.com") do
        target_url = "https://fdo.cr/about"
        get "/?r=#{target_url}"

        response.status_code.should eq(302)
        response.headers["Location"].should eq(target_url)
      end
    end

    it "allows redirect to DEFAULT_DESTINATION host even if not in WHITELIST_DESTINATIONS" do
      with_default_destination("https://fdo.cr") do
        with_whitelist_destinations("example.com") do
          target_url = "https://fdo.cr/about"
          get "/?r=#{target_url}"

          response.status_code.should eq(302)
          response.headers["Location"].should eq(target_url)
        end
      end
    end

    it "redirects to DEFAULT_DESTINATION when root path has no r parameter and DEFAULT_DESTINATION is set" do
      with_default_destination("https://example.com") do
        get "/"

        response.status_code.should eq(302)
        response.headers["Location"].should eq("https://example.com")
      end
    end

    it "serves static apple-app-site-association file" do
      get "/.well-known/apple-app-site-association"

      response.status_code.should eq(200)
      response.headers["Content-Type"].should eq("application/json")
    end

    it "serves static assetlinks.json file" do
      get "/.well-known/assetlinks.json"

      response.status_code.should eq(200)
      response.headers["Content-Type"].should eq("application/json")
    end
  end

  context "failure" do
    it "renders fallback page if target redirect not provided and DEFAULT_DESTINATION is not set" do
      without_default_destination do
        get "/"

        response.status_code.should eq(200)
        response.body.should contain("Something went wrong")
        response.body.should contain("Check the server configuration for more details")
      end
    end

    it "renders fallback page if requesting any other path and DEFAULT_DESTINATION is not set" do
      without_default_destination do
        get "/about-us"

        response.status_code.should eq(200)
        response.body.should contain("Something went wrong")
        response.body.should contain("Check the server configuration for more details")
      end
    end

    it "renders fallback page if r parameter is an invalid URL" do
      get "/?r=poorthing-ble$$-ur-<3"

      response.status_code.should eq(200)
      response.body.should contain("Something went wrong")
      response.body.should contain("Check the server configuration for more details")
    end

    it "renders fallback page if WHITELIST_DESTINATIONS is set and destination host is not allowed" do
      with_whitelist_destinations("example.com") do
        target_url = "https://fdo.cr/about"
        get "/?r=#{target_url}"

        response.status_code.should eq(200)
        response.body.should contain("Something went wrong")
        response.body.should contain("Check the server configuration for more details")
      end
    end
  end
end
