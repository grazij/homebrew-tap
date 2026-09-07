cask "grazij-caffeine" do
  # Tags carry a `+grazij.N` suffix, which Version.detect misparses; declare it
  # explicitly and pin the livecheck regex to match.
  version "1.6.4+grazij.1"
  sha256 "af0435be77450674bf01741ad46ff6a704362435df79c0d68aa3b576f8ea61d7"

  url "https://github.com/grazij/Caffeine/releases/download/v#{version}/Caffeine-#{version}.dmg"
  name "Caffeine"
  desc "Menu bar utility that prevents the system from going to sleep"
  homepage "https://github.com/grazij/Caffeine"

  livecheck do
    url :url
    strategy :github_latest
    regex(/^v?(\d+(?:\.\d+)+\+grazij\.\d+)$/i)
  end

  # Sparkle is linked but never started, and the app has no other updater, so
  # Homebrew is the only thing that upgrades this cask. auto_updates true would
  # make `brew upgrade` skip it unless --greedy were passed.
  auto_updates false
  conflicts_with cask: [
    "caffeine",
    "domzilla-caffeine",
  ]
  depends_on macos: :sonoma

  app "Caffeine.app"

  # Runs as an LSUIElement agent (NSApp.setActivationPolicy(.accessory)), so it
  # must be terminated before the bundle is removed.
  uninstall quit: "com.miacloud.caffeine"

  # The app is sandboxed, so every preference it writes lands inside its
  # container; no loose ~/Library/Preferences plist is created. Verified against
  # an installed build of upstream 1.6.4: only these two paths existed.
  zap trash: [
    "~/Library/Application Scripts/com.miacloud.caffeine",
    "~/Library/Containers/com.miacloud.caffeine",
  ]
end
