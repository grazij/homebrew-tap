class Pathset < Formula
  desc "Tiny C utility that turns a directory list into a PATH value"
  homepage "https://github.com/grazij/pathset"
  url "https://github.com/grazij/pathset/archive/refs/tags/v0.6.0.tar.gz"
  sha256 "32db69579425f06a2b9b0599e17449a7209f68c351e8cac76f66293c66da3229"
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
    # These assertions are the contract 0.5.0 and 0.6.0 settled: a plain entry
    # is always emitted, `?` is the checked form, only a failed expansion
    # counts as a skip, and -s joins with a space. -f replaced -c and -k in
    # 0.6.0; a config given as a path must contain a '/', which testpath
    # always does.

    # A plain entry is emitted whatever the directory check says. Dropping a
    # live entry would rewrite the order the config declared; emitting a dead
    # one costs a single failed lookup.
    cfg = testpath/"plain"
    cfg.write "#{testpath}\n/nonexistent/dir\n"
    assert_equal "#{testpath}:/nonexistent/dir",
                 shell_output("#{bin}/pathset -f #{cfg} -q 2>/dev/null").strip

    # `?` marks a conditional entry: checked first, dropped silently when it
    # is not an existing, readable, non-empty directory.
    cfg = testpath/"conditional"
    cfg.write "#{testpath}\n?/nonexistent/dir\n"
    assert_equal testpath.to_s,
                 shell_output("#{bin}/pathset -f #{cfg} -q").strip

    # A failed expansion is the one thing that still skips, and skips are what
    # produce exit 3 — the directory check never does.
    cfg = testpath/"skip"
    cfg.write "#{testpath}\n$PATHSET_UNSET_IN_TEST/bin\n"
    assert_equal testpath.to_s,
                 shell_output("#{bin}/pathset -f #{cfg} -q 2>/dev/null", 3).strip

    # -s is why 0.6.0 exists for zsh users: the result has to read back as a
    # shell array. Two entries are enough to pin the separator; the matching
    # ':'-becomes-representable half is covered by the upstream suite, not
    # here, because a ':' in a directory name is not portable enough to build
    # an install-time test on.
    cfg = testpath/"space"
    cfg.write "#{testpath}\n#{testpath}\n"
    assert_equal "#{testpath} #{testpath}",
                 shell_output("#{bin}/pathset -f #{cfg} -s -q").strip

    assert_match version.to_s, shell_output("#{bin}/pathset -V")
  end
end
