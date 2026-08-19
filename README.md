# Homebrew Tap

## Formulae

`brew install grazij/tap/<formula>`

| Formula | Description |
| --- | --- |
| `duti` | [FORK](https://github.com/grazij/duti): Set macOS default applications for document types and URL schemes |
| `git-credential-1password` | [REPO](https://github.com/ethrgeist/git-credential-1password): Git credential helper that R/W credentials via the 1Password CLI |
| `pathset` | [REPO](https://github.com/grazij/pathset): Utility that turns a directory list into a PATH value |
| `plistwatch` | [FORK](https://github.com/grazij/plistwatch): Monitors and logs macOS defaults changes |

## Casks

`brew install --cask grazij/tap/<cask>`

| Cask | Description |
| --- | --- |
| `sensible-side-buttons` | [FORK](https://github.com/grazij/sensible-side-buttons): Adds support for side mouse buttons navigation (macOS 11+) |

## External commands

`brew caveats <formula|cask>...`

Homebrew refuses to load an external command from a tap you have not trusted, so
this one needs a `brew trust` as well as the tap:

```sh
brew tap grazij/tap
brew trust grazij/tap
```

| Command | Description |
| --- | --- |
| `caveats` | [UPSTREAM](https://github.com/rafaelgarrido/homebrew-caveats): Print the caveats of formulae and casks without installing them |

`caveats` is vendored from [rafaelgarrido/homebrew-caveats][caveats-upstream] by
Rafael Garrido, MIT licensed. Only formatting was changed; the copyright and
permission notice are kept in `cmd/caveats.rb`.

[caveats-upstream]: https://github.com/rafaelgarrido/homebrew-caveats

## Contributing

Formulae are authored here and nowhere else. See [CONTRIBUTING.md](CONTRIBUTING.md)
for how to bump one and why it has to go through a pull request.
