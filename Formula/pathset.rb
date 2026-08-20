class Pathset < Formula
  desc "Tiny C utility that turns a directory list into a PATH value"
  homepage "https://github.com/grazij/pathset"
  url "https://github.com/grazij/pathset/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "1e70b2ef1a1dcd8ace4072ab9c83567f048535a0f470baa6b921dc87a63fecfb"
  license "MIT"
  head "https://github.com/grazij/pathset.git", branch: "main"

  def install
    # Plain `build`: no help2man (pathset.1 ships pre-generated in the
    # tarball) and no test run — correctness is settled upstream by CI and
    # by `make release` before tagging, not on the installer's machine.
    system "make", "build", "VERSION=#{version}"
    bin.install "pathset"
    man1.install "pathset.1"
    pkgshare.install "examples"
  end

  test do
    # 0.5.0 inverted the entry contract, so these assertions are the contract:
    # a plain entry is always emitted, `?` is the checked form, and only a
    # failed expansion counts as a skip.

    # A plain entry is emitted whatever the directory check says. Dropping a
    # live entry would rewrite the order the config declared; emitting a dead
    # one costs a single failed lookup.
    cfg = testpath/"plain"
    cfg.write "#{testpath}\n/nonexistent/dir\n"
    assert_equal "#{testpath}:/nonexistent/dir",
                 shell_output("#{bin}/pathset -c #{cfg} -q 2>/dev/null").strip

    # `?` marks a conditional entry: checked first, dropped silently when it
    # is not an existing, readable, non-empty directory.
    cfg = testpath/"conditional"
    cfg.write "#{testpath}\n?/nonexistent/dir\n"
    assert_equal testpath.to_s,
                 shell_output("#{bin}/pathset -c #{cfg} -q").strip

    # A failed expansion is the one thing that still skips, and skips are what
    # produce exit 3 — the directory check never does.
    cfg = testpath/"skip"
    cfg.write "#{testpath}\n$PATHSET_UNSET_IN_TEST/bin\n"
    assert_equal testpath.to_s,
                 shell_output("#{bin}/pathset -c #{cfg} -q 2>/dev/null", 3).strip

    assert_match version.to_s, shell_output("#{bin}/pathset -V")
  end
end
