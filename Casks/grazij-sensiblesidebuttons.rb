cask "grazij-sensiblesidebuttons" do
  version "1.0.6-grazij.1"
  sha256 "4db1b01c5acc149d946eb8249735a6a33c7134c7d6bf6bbf4b2a927329a019f7"

  url "https://github.com/grazij/sensible-side-buttons/releases/download/v#{version}/SensibleSideButtons-#{version}.dmg"
  name "Sensible Side Buttons"
  desc "Makes side mouse buttons perform swipe gestures for navigation"
  homepage "https://sensible-side-buttons.archagon.net"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates false

  app "SensibleSideButtons.app"

  postflight do
    system_command "open",
                   args: ["-a", "System Preferences"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Preferences/net.archagon.sensible-side-buttons.plist",
    "~/Library/Preferences/com.miacloud.sensible-side-buttons.plist",
  ]

  caveats <<~EOS
    SensibleSideButtons requires Accessibility permissions to function.

    To grant permissions:
      1. Open System Settings (or System Preferences)
      2. Go to Privacy & Security > Accessibility
      3. Add SensibleSideButtons and enable it

    To launch at login:
      1. Open System Settings > General > Login Items
      2. Add SensibleSideButtons to your login items

    Note: You may need to right-click the app and select "Open" the first time
    you run it to bypass Gatekeeper security warnings.
  EOS
end
