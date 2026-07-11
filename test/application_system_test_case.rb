require "test_helper"
require "selenium/webdriver"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # En CI, `google-chrome` est sur le PATH : la config par défaut suffit.
  # En local, Chrome peut être fourni par le paquet snap `chromium`. On pointe
  # alors le binaire (Selenium Manager résout un chromedriver compatible ; le
  # chromedriver embarqué dans le snap ne démarre pas hors de son confinement).
  CHROMIUM = "/snap/bin/chromium"

  if File.exist?(CHROMIUM)
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
      options.binary = CHROMIUM
      options.add_argument("--headless=new")
      options.add_argument("--no-sandbox")
      options.add_argument("--disable-gpu")
      options.add_argument("--disable-dev-shm-usage")
      # Le confinement snap bloque le profil temporaire créé par défaut sous
      # /tmp : on le place dans l'arborescence accessible en écriture du snap.
      snap_common = File.join(Dir.home, "snap", "chromium", "common")
      base = Dir.exist?(snap_common) ? snap_common : Dir.home
      profile = File.join(base, "mapline-system-tests", SecureRandom.hex(4))
      FileUtils.mkdir_p(profile)
      options.add_argument("--user-data-dir=#{profile}")
    end
  else
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
  end
end
