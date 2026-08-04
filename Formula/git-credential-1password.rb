class GitCredential1password < Formula
  desc "Git credential helper that reads and writes credentials via the 1Password CLI"
  homepage "https://github.com/ethrgeist/git-credential-1password"
  url "https://github.com/ethrgeist/git-credential-1password/archive/refs/tags/v1.5.0.tar.gz"
  sha256 "2fb4280c17a075ad5b0de8957712ed335d97728f85909730206dec9ec4ae632a"
  license "MIT"
  head "https://github.com/ethrgeist/git-credential-1password.git", branch: "main"

  depends_on "go" => :build

  def install
    # upstream derives the version from debug.ReadBuildInfo, which reports
    # "(devel)" for a tarball build — stamp it so `--version` is meaningful.
    system "go", "build", *std_go_args(ldflags: "-X main.version=#{version}")
  end

  def caveats
    <<~EOS
      This helper shells out to the 1Password CLI, which ships as a cask:
        brew install --cask 1password-cli
        op whoami

      Enable it for all hosts:
        git config --global credential.helper "1password"

      Items must be tagged "git-credential-1password" in 1Password unless you
      pin one with --id. See the upstream README for the full flag list.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/git-credential-1password --version 2>&1")

    # no action argument is a usage error; confirms the binary runs without `op`
    output = shell_output("#{bin}/git-credential-1password 2>&1", 2)
    assert_match "usage: git credential-1password", output
  end
end
