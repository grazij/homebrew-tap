class Plistwatch < Formula
  desc "Watch macOS defaults and print the commands that recreate each change"
  homepage "https://github.com/grazij/plistwatch"
  url "https://github.com/grazij/plistwatch/archive/refs/tags/v2025.09.24%2Bgrazij.4.tar.gz"
  version "2025.09.24+grazij.4"
  sha256 "5a3eff06da4934b07d450dc5f2c376591baefc076482e1090a2c2b0028269ec0"
  license "MIT"
  head "https://github.com/grazij/plistwatch.git", branch: "main"

  # Version.detect reads a "+grazij.N" tarball name as "1", so `version` above
  # is pinned by hand and livecheck needs an explicit regex.
  livecheck do
    url :stable
    strategy :github_latest
    regex(/v?(\d+(?:\.\d+)+\+grazij\.\d+)/i)
  end

  depends_on "go" => :build
  depends_on :macos

  def install
    # std_go_args already adds `-s -w` itself (and drops them for
    # --debug-symbols builds), so don't pass them again.
    system "go", "build", *std_go_args
  end

  test do
    assert_equal "plistwatch #{version}", shell_output("#{bin}/plistwatch --version").strip
  end
end
