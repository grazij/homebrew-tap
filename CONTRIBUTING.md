# Contributing

## What this repo is

A third-party Homebrew tap: Ruby formula files under `Formula/`, cask files
under `Casks/`, no application source.

**Formulae are authored here and nowhere else.** The projects this tap packages
no longer keep a copy of their own.

`Formula/git-credential-1password.rb` is the deliberate exception to packaging
the `grazij/*` org: it points at `ethrgeist/git-credential-1password` directly
rather than at a fork, so upstream can retag and change the tarball checksum,
which surfaces as a mismatch on the next build.

## Bumping a formula

```sh
./bump.sh duti 1.5.5+grazij.6      # --dry-run first if you want to see it
```

The tag must already be pushed — GitHub generates the tarball on demand, so its
checksum does not exist before then. `bump.sh` downloads what GitHub serves,
checks it really is an archive, rewrites `url` / `version` / `sha256`, and opens
a pull request.

The bump commit is cut from whatever is checked out, so `bump.sh` refuses a
dirty tree or a branch not level with `origin` rather than carry either into the
pull request.

Never compute the checksum from a local `git archive`, and never carry one over
from a previous tag of the same tree. An archive's pax global header contains
the commit SHA, so re-tagging changes the checksum even when the tree it
contains is byte-identical.

## CI

**Changes go through a pull request, not a direct push to `main`.**

- `.github/workflows/tests.yml` — `brew test-bot` on `ubuntu-24.04`,
  `macos-15-intel` and `macos-26`. `--only-formulae` (build + bottle) on pull
  requests only; pushes to `main` get `--only-tap-syntax`. `fail-fast: false` is
  deliberate: Linux is expected to skip macOS-only formulae rather than block
  the matrix.
- `.github/workflows/publish.yml` — applying the `pr-pull` label to a pull
  request runs `brew pr-pull`, which pulls the bottle artifacts from the test
  run, commits them to `main` and deletes the branch. Do not hand-edit bottle
  blocks; they land via that label.

Merging with the ordinary merge button instead of the label lands the formula
with **no bottle block**. Casks have no bottles, so a direct push loses nothing
there.

## Working on a formula locally

```sh
brew style --fix grazij/tap               # the whole tap, which is what CI checks
brew test-bot --only-tap-syntax           # what CI actually runs
brew test <name>                          # run the formula's `test do` block
brew tap --force grazij/tap && brew readall grazij/tap
```

**Lint the tap, not a list of files.** `brew style grazij/tap` covers the shell
scripts here as well as the Ruby, and it applies Homebrew's own profiles:
shellcheck with `require-variable-braces` on (so `$VAR` must be `${VAR}`) and
shfmt with two-space indent and `then` on its own line. `brew style Formula/*.rb`
passes happily while the tap as a whole fails.

**For shell, also run shellcheck at its strictest.** The runner installs a newer
one that enables checks yours does not, so a local `brew style` can pass while
CI fails.

```sh
shellcheck -s bash --enable=all bump.sh
```

`brew audit` and `brew livecheck` refuse a bare file path
(`Error: Calling brew audit [path ...] is disabled`), so they run by name
against the tapped clone:

```sh
brew audit --strict --online grazij/tap/<name>
brew audit --cask --strict --online grazij/tap/<name>
brew livecheck --cask grazij/tap/<name>
```

To exercise a file that is not committed yet, copy it into
`$(brew --repository grazij/tap)/Formula/`, run the by-name commands, then
`git -C "$(brew --repository grazij/tap)" checkout -- Formula/<name>.rb`. That
tapped clone is a different checkout from this one, and `brew update` resets it;
leaving a stray copy behind makes the next `brew update` fail on an untracked
file.

## Formula conventions

- `depends_on :macos` on macOS-only tools. The Linux CI runner relies on it to
  skip them.
- Non-obvious build workarounds carry an inline comment giving the *reason*, not
  the *what*. Preserve those comments through a bump.
- A tag with a `+grazij.N` suffix (`v1.5.5+grazij.6`) is misparsed by Homebrew's
  `Version.detect` as `1`, so the formula must declare `version` explicitly
  **and** carry a `livecheck` block with a matching regex. Both are needed; one
  alone does not work. See `Formula/duti.rb`.
- Go formulae: `system "go", "build", *std_go_args` on its own — `std_go_args`
  already supplies `-s -w`, and repeating them breaks `--debug-symbols` builds.
  Where the tool derives its own version from `debug.ReadBuildInfo` (which
  yields `(devel)` for a tarball build, there being no VCS metadata), stamp it
  with the keyword argument — `*std_go_args(ldflags: "-X main.version=#{version}")`
  — rather than a hand-written second `-ldflags`.
- A runtime dependency that only ships as a **cask** cannot be a formula
  `depends_on`. Name it in a `caveats` block instead
  (`git-credential-1password` → `1password-cli`).

## Cask conventions

- `depends_on macos:` takes a bare symbol for the *minimum* release —
  `depends_on macos: :big_sur`. The `">= :big_sur"` string form is valid but
  `brew style` autocorrects it. `maximum_macos:` is the `<=` direction. Match it
  to the app's real `LSMinimumSystemVersion` rather than guessing.
- Menu bar agents need `uninstall quit: "<bundle-id>"`, or the running process
  survives `brew uninstall` and races the bundle removal.
- Prefer `caveats` over `postflight` for permission setup. A `postflight` that
  opens System Settings fires on every install and surprises the user.
- `zap trash:` arrays are alphabetized by `brew style`, and `homepage` needs a
  trailing slash after a bare domain. Both are autocorrectable — run `--fix`.

## Removing a formula or cask

Deleting the `.rb` file is the whole operation.
