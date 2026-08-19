class Pathset < Formula
  desc "Tiny C utility that turns a directory list into a PATH value"
  homepage "https://github.com/grazij/pathset"
  url "https://github.com/grazij/pathset/archive/refs/tags/v0.4.0.tar.gz"
  sha256 "4552dca823b2eb609d6353e99e214a88a7c1574d6f1708035d0bda90057cbd94"
  license "MIT"
  head "https://github.com/grazij/pathset.git", branch: "main"

  def install
    # Plain `build`: no help2man (pathset.1 ships pre-generated in the
    # tarball) and no test run — correctness is settled by `make release`
    # before tagging, not on the installer's machine.
    system "make", "build", "VERSION=#{version}"
    bin.install "pathset"
    man1.install "pathset.1"
    pkgshare.install "examples"
  end

  test do
    cfg = testpath/"config"
    cfg.write <<~EOS
      #{testpath}
      /nonexistent/dir
    EOS

    # Bare colon-joined output, exit 3 because /nonexistent/dir is skipped.
    output = shell_output("#{bin}/pathset -c #{cfg} -q", 3)
    assert_equal testpath.to_s, output.strip

    # -V prints version.
    assert_match version.to_s, shell_output("#{bin}/pathset -V")
  end
end
