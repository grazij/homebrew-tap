cask "caffeine" do
  version "1.5.3-grazij.2"
  sha256 "7f214c8f1e3b780aabc0631ee267ba5c94fa9e4d4eb67f7125c944b0278cdfce"

  url "https://github.com/grazij/Caffeine/releases/download/v1.5.3-grazij.2/Caffeine-1.5.3-grazij.2.dmg"
  name "Caffeine"
  desc "A macOS application"
  homepage "https://github.com/grazij/Caffeine"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :big_sur"

  app "Caffeine.app"

  zap trash: [
    "~/Library/Preferences/com.miacloud.caffeine.plist",
    "~/Library/Application Support/Caffeine",
    "~/Library/Caches/com.miacloud.caffeine",
  ]
end
