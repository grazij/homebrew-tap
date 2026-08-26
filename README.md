# Homebrew Tap

A third-party Homebrew tap: formulae and casks.

## Install

```sh
brew tap grazij/tap
brew trust grazij/tap
```

## Formulae

| Formula | Description | Source |
| --- | --- | --- |
| `duti` | Set macOS default applications for document types and URL schemes | [FORK](https://github.com/grazij/duti) |
| `git-credential-1password` | Git credential helper that R/W credentials via the 1Password CLI | [REPO](https://github.com/ethrgeist/git-credential-1password) |
| `pathset` | Utility that turns a directory list into a PATH value | [REPO](https://github.com/grazij/pathset) |
| `plistwatch` | Monitors and logs macOS defaults changes | [FORK](https://github.com/grazij/plistwatch) |

## Casks

| Cask | Description | Source |
| --- | --- | --- |
| `sensible-side-buttons` | Adds support for side mouse buttons navigation (macOS 11+) | [FORK](https://github.com/grazij/sensible-side-buttons) |

## Commands

External `brew` commands moved out of this tap. They live in
[grazij/homebrew-extras](https://github.com/grazij/homebrew-extras), tapped as
`grazij/extras`.

## Contributing

Formulae are authored here and nowhere else. See [CONTRIBUTING.md](CONTRIBUTING.md)
for how to bump one and why it has to go through a pull request.

## License

MIT — see [LICENSE.md](LICENSE.md).
