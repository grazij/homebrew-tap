cask "sensible-side-buttons" do
  # Tags use a `+grazij.N` suffix, which Version.detect misparses; declare it
  # explicitly and pin the livecheck regex to match.
  version "1.0.6+grazij.2"
  sha256 "85f8359248b855fd8264d60c44946fd7a9d84ccce8e23f8158855464e39633b8"

  url "https://github.com/grazij/sensible-side-buttons/releases/download/v#{version}/SensibleSideButtons-#{version}.dmg"
  name "Sensible Side Buttons"
  desc "Makes side mouse buttons perform swipe gestures for navigation"
  homepage "https://sensible-side-buttons.archagon.net/"

  livecheck do
    url :url
    strategy :github_latest
    regex(/^v?(\d+(?:\.\d+)+\+grazij\.\d+)$/i)
  end

  auto_updates false
  depends_on macos: :big_sur

  app "SensibleSideButtons.app"

  # Runs as a menu bar agent, so it must be terminated before the bundle is removed.
  uninstall quit: "com.miacloud.sensible-side-buttons"

  zap trash: [
    "~/Library/Preferences/com.miacloud.sensible-side-buttons.plist",
    "~/Library/Preferences/net.archagon.sensible-side-buttons.plist",
  ]

  caveats <<~EOS
    SensibleSideButtons needs Accessibility permission to work. macOS prompts
    for it the first time you enable the app. If no prompt appears, add
    SensibleSideButtons manually under
    System Settings > Privacy & Security > Accessibility.

    For launch-at-login instructions, see:
      https://github.com/grazij/sensible-side-buttons#launch-at-login
  EOS
end
