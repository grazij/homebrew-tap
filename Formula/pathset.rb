class Pathset < Formula
  desc "Tiny C utility that turns a directory list into a PATH value"
  homepage "https://github.com/grazij/pathset"
  url "https://github.com/grazij/pathset/archive/refs/tags/v0.7.2.tar.gz"
  sha256 "2e67b326fd5f1ae430e272ac6ce19d0d807a1faa86f85bae60850a4bf0788273"
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
    # These assertions are the contract 0.5.0 through 0.7.2 settled: a plain
    # entry is always emitted, `?` is the checked form, only a failed
    # expansion counts as a skip, -s joins with a space, and duplicates are
    # always dropped. -f replaced -c and -k in 0.6.0; a config given as a path
    # must contain a '/', which testpath always does.

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
    # an install-time test on. The two must be *distinct* directories since
    # 0.7.0 — repeating one collapses it and pins nothing.
    (testpath/"sub").mkpath
    cfg = testpath/"space"
    cfg.write "#{testpath}\n#{testpath}/sub\n"
    assert_equal "#{testpath} #{testpath}/sub",
                 shell_output("#{bin}/pathset -f #{cfg} -s -q").strip

    # 0.7.0 dropped -d and made dedup unconditional. A trailing slash does not
    # make an entry distinct, and the flag is a usage error now rather than a
    # silent no-op, so an rc file still passing it fails loudly.
    cfg = testpath/"dupes"
    cfg.write "#{testpath}\n#{testpath}/\n"
    assert_equal testpath.to_s,
                 shell_output("#{bin}/pathset -f #{cfg} -q").strip
    assert_match "unknown argument: -d",
                 shell_output("#{bin}/pathset -f #{cfg} -q -d 2>&1", 2)

    # 0.7.1 stopped printing the whole help to stderr on an argument error --
    # it buried the one line that said what was wrong under 67 others. The
    # message text is unchanged, so what is pinned here is the *shape*: the
    # error, a pointer to --help, and no usage dump.
    err = shell_output("#{bin}/pathset -z 2>&1", 2)
    assert_match "unknown argument: -z", err
    assert_match "Try 'pathset --help' for more information.", err
    refute_match(/^Usage:/, err)

    # 0.7.1 also fixed --file NAME rejecting whatever option followed it:
    # getopt_long leaves optind two past the token in that spelling, so
    # `--file cfg --check` died with "unknown argument: --check". Only the
    # two-token form was affected, which is why -f above never caught it.
    cfg = testpath/"longopt"
    cfg.write "#{testpath}\n"
    system bin/"pathset", "--file", cfg, "--check"

    assert_match version.to_s, shell_output("#{bin}/pathset -V")
  end
end
