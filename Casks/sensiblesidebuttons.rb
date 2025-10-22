cask "sensiblesidebuttons" do
  version "1.0.6-grazij.1"
  sha256 "7b892bb9ae6c1abbd232bc9ff151ed3b4663b0e9dfd161f02de14470b498b280"

  url "https://github.com/grazij/sensible-side-buttons/releases/download/v1.0.6-grazij.1/SensibleSideButtons-1.0.6-grazij.1.dmg"
  name "SensibleSideButtons"
  desc "A macOS application"
  homepage "https://github.com/grazij/sensible-side-buttons"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :big_sur"

  app "SensibleSideButtons.app"

  zap trash: [
    "~/Library/Preferences/com.miacloud.swipesimr.plist",
    "~/Library/Application Support/SensibleSideButtons",
    "~/Library/Caches/com.miacloud.swipesimr",
  ]
end
