# Homebrew Tap

## Formulae

`brew install grazij/tap/<formula>`

| Formula | Description |
| --- | --- |
| `duti` | [FORK](https://github.com/grazij/duti): Set macOS default applications for document types and URL schemes |
| `git-credential-1password` | [REPO](https://github.com/ethrgeist/git-credential-1password): Git credential helper that reads and writes credentials via the 1Password CLI |
| `pathset` | [REPO](https://github.com/grazij/pathset): Tiny C utility that turns a directory list into a PATH value |
| `plistwatch` | [FORK](https://github.com/grazij/plistwatch): Watch macOS defaults and print the commands that recreate each change |

## Casks

`brew install --cask grazij/tap/<cask>`

| Cask | Description |
| --- | --- |
| `sensible-side-buttons` | [FORK](https://github.com/grazij/sensible-side-buttons): Makes side mouse buttons perform swipe gestures for navigation (macOS 11+) |

## Troubleshooting

If `brew update` fails on this tap — `could not apply …`, a rebase it cannot
finish, or a complaint about unrelated histories — your clone predates a history
rewrite here. Reset it to match:

```sh
TAP="$(brew --repository grazij/tap)"
git -C "$TAP" rebase --abort 2>/dev/null || true
git -C "$TAP" fetch --prune origin
git -C "$TAP" reset --hard origin/main
brew update
```

Nothing you have installed is affected and no reinstall is needed.

Do **not** run `brew untap grazij/tap` to fix this. Untapping discards the clone
outright, and anything you have committed there locally goes with it.

## Contributing

Formulae are authored here and nowhere else. See [CONTRIBUTING.md](CONTRIBUTING.md)
for how to bump one and why it has to go through a pull request.

## Documentation

`brew help`, `man brew` or check [Homebrew's documentation](https://docs.brew.sh).
