# sym

A simple dotfile symlinker. A focused alternative to GNU Stow with saner defaults.

## Installation

A single POSIX sh script with no dependencies. Copy `sym` anywhere on your `$PATH`.

```
usage: sym [-t TARGET] [-d] [--dry-run] [-v] [--exclude PATTERN]... SOURCE
```

`TARGET` defaults to `$HOME`. `SOURCE` is a directory whose contents are mirrored as symlinks into `TARGET`.

```
~/dotfiles/
├── bash/
│   └── .bashrc
└── mpv/
    └── .config/
        └── mpv/
            └── mpv.conf
```

```sh
cd ~/dotfiles
sym bash          # creates ~/.bashrc -> dotfiles/bash/.bashrc
sym mpv           # creates ~/.config/mpv/mpv.conf -> dotfiles/mpv/.config/mpv/mpv.conf
sym -d bash       # removes ~/.bashrc
```

Always use `--dry-run` first.


## Behaviour

- Symlinks are always relative
- Intermediate directories are created as needed
- On deletion, empty directories left behind are removed
- Two-pass: all conflicts are reported before any changes are made
- Idempotent: re-linking an already-correct symlink is a no-op


## vs GNU Stow

Stow targets a different use case (package management) and its defaults reflect that. For dotfiles you typically need:

```sh
stow --no-folding -t "$HOME" -d category package
```

With `sym`, the same result is just:

```sh
sym category/package
```

Differences from Stow:
- `$HOME` is the default target (not `$PWD/..`)
- Slash-separated source paths are supported
- Tree folding is not done and not supported
- Source directory may itself be a symlink

