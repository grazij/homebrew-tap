# Contributing

## What this repo is

A third-party Homebrew tap. The content is Ruby formula files under `Formula/`
and cask files under `Casks/` — there is no application source here. Users
install with `brew install grazij/tap/<formula>` or
`brew install --cask grazij/tap/<cask>`.

Most formulae package software from the `grazij/*` GitHub org, so the upstream
repo, tag and tarball checksum are all under the same owner's control.

`Formula/git-credential-1password.rb` is the deliberate exception: it points at
`ethrgeist/git-credential-1password` directly rather than at a fork. The
trade-off is that upstream can retag and change the tarball checksum, which
surfaces as a mismatch on the next build.

**Formulae are authored here and nowhere else.** The projects this tap packages
used to keep their own copy and mirror it across; three of them did it three
different ways and none reached the tap reliably, so their copies are gone.

## Bumping a formula

```sh
./bump.sh duti 1.5.5+grazij.6      # --dry-run first if you want to see it
```

The tag must already be pushed — GitHub generates the tarball on demand, so its
checksum does not exist before then. `bump.sh` downloads what GitHub serves,
checks it really is an archive, rewrites `url` / `version` / `sha256`, and opens
a pull request.

Never compute the checksum from a local `git archive`, and never carry one over
from a previous tag of the same tree. An archive's pax global header contains
the commit SHA, so re-tagging changes the checksum even when the tree it
contains is byte-identical.

**Changes go through a pull request, not a direct push to `main`.** `--only-formulae`
runs on pull requests only, so a direct push never builds bottles. Casks have no
bottles, so `--only-formulae` skips them and a direct push loses nothing there;
`--only-tap-syntax` still lints them on every push.

## CI

- `.github/workflows/tests.yml` — `brew test-bot` on `ubuntu-24.04`,
  `macos-15-intel` and `macos-26`. `--only-formulae` (build + bottle) on pull
  requests; pushes to `main` get syntax only. `fail-fast: false` is deliberate:
  Linux is expected to skip macOS-only formulae rather than block the matrix.
- `.github/workflows/publish.yml` — applying the `pr-pull` label to a pull
  request runs `brew pr-pull`, which pulls the bottle artifacts from the test
  run, commits them to `main` and deletes the branch. Do not hand-edit bottle
  blocks; they land via that label.

Merging with the ordinary merge button instead of the label lands the formula
with **no bottle block**. That is what happened to `git-credential-1password`,
and it was left that way on purpose — a 2.3 MB Go binary that builds in about a
second does not need bottles.

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
passes happily while the tap as a whole fails, which is exactly how `bump.sh`
reached `main` red.

**For shell, also run shellcheck at its strictest — the runner is ahead of you.**

```sh
shellcheck -s bash --enable=all bump.sh
```

A local `brew style` can pass while CI fails, because the runner installs a
newer shellcheck that enables checks yours does not. `SC2310` cost a second red
build this way: a function called in an `||` condition disables `set -e` for
everything it goes on to call. The fix is to let the function exit on its own
rather than pairing it with `|| die`.

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
