# Commands

This tap ships one external `brew` command. Homebrew loads it only after
`brew trust grazij/tap`, which [README.md](README.md#install) covers.

## `caveats`

Print the caveats of formulae and casks without installing them.

```
brew caveats [<options>] [<formula>|<cask> ...]
```

Name a formula or cask to describe it. Name nothing and it describes everything
installed — every cask, and every formula you asked for by name. Formulae that
arrived only as another formula's dependency are skipped, because a caveat about
linking `readline` is not one you can act on; `--all` includes them.

```sh
brew caveats            # everything you installed on purpose
brew caveats --all      # plus the formulae pulled in as dependencies
brew caveats --casks    # casks only; --formulae for the other half
brew caveats readline   # a named argument is never skipped
```

| Flag | Effect |
| --- | --- |
| `--formula`, `--formulae` | Treat all named arguments as formulae. |
| `--cask`, `--casks` | Treat all named arguments as casks. |
| `--all` | Also describe formulae installed only as a dependency of another formula. Has no effect when a formula or cask is named. |

`--formula` and `--cask` conflict. Either one also narrows the set that gets
described when nothing is named.

### Origin

Vendored from [rafaelgarrido/homebrew-caveats][upstream] by Rafael Garrido, MIT
licensed. This copy diverges in three ways, all recorded at the top of
`cmd/caveats.rb`:

- **Formatting**, to satisfy `brew style` in this tap.
- **Output gating**, so a name with nothing to say prints nothing. Upstream
  prints a blank line per named argument rather than per printed block, and a
  bare `==> name: Caveats` header for a formula whose only caveats are shell
  completions.
- **The no-argument default** described above. Upstream requires a name.

[upstream]: https://github.com/rafaelgarrido/homebrew-caveats
