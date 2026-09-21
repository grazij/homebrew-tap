class GrazijPlistwatch < Formula
  desc "Watch macOS defaults and print the commands that recreate each change"
  homepage "https://github.com/grazij/plistwatch"
  url "https://github.com/grazij/plistwatch/archive/refs/tags/v2025.09.24%2Bgrazij.9.tar.gz"
  version "2025.09.24+grazij.9"
  sha256 "84651168fda2de631721566f233f67ffa1589fb5909c1d85f7f9e90fb613d9ce"
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
    # --debug-symbols builds), so don't pass them again. `output` is explicit
    # because it otherwise defaults to the formula name, which would install
    # the binary as grazij-plistwatch.
    system "go", "build", *std_go_args(output: bin/"plistwatch")
  end

  test do
    assert_equal "plistwatch #{version}", shell_output("#{bin}/plistwatch --version").strip
  end
end
