# Markus's dotfiles

Managed with [chezmoi](https://www.chezmoi.io/). The repo itself is a chezmoi
source directory: files are named using chezmoi's `dot_*` / `private_*`
conventions and rendered directly into `$HOME` (no symlinks back into the
repo).

## Layout

```
.chezmoi.toml.tmpl                  # prompts for macos/vim/installTmux/installZsh + git identity
.chezmoiignore                      # conditional files (vimrc, ghostty)
dot_zshrc                           # ~/.zshrc
dot_bashrc                          # ~/.bashrc (execs zsh if installed)
dot_tmux.conf                       # ~/.tmux.conf
dot_gitconfig.tmpl                  # ~/.gitconfig (user.name/email templated)
dot_vimrc                           # ~/.vimrc         (when vim=true)
private_dot_config/zsh/aliases.sh   # ~/.config/zsh/aliases.sh   (sourced by zshrc)
private_dot_config/zsh/extras.sh    # ~/.config/zsh/extras.sh
private_dot_config/zsh/slurm.sh     # ~/.config/zsh/slurm.sh
private_dot_config/zsh/p10k.zsh     # ~/.config/zsh/p10k.zsh
private_dot_config/ghostty/config   # ~/.config/ghostty/config  (when macos=true)
dot_aerospace.toml                 # ~/.aerospace.toml         (when macos=true)
run_onchange_install-dependencies.sh.tmpl  # brew/apt deps + oh-my-zsh + plugins
iterm/                              # iterm colour schemes (import manually, macOS only)
```

## Setup

### 1. Install chezmoi

macOS:
```bash
brew install chezmoi
```
Server / Ubuntu:
```bash
sh -c "$(curl -fsSL https://get.chezmoi.io)" -- -b "$HOME/.local/bin"
```

### 2. Init from this repo

This clones the repo to `~/.local/share/chezmoi` and prompts for the options
that used to be `--local` / `--vim` / `--tmux` / `--zsh`:

```bash
chezmoi init --apply git@github.com:HennerM/dotfiles.git
```

You will be asked:
- `Git user.name` — your name for commits
- `Git user.email` — your email for commits
- `macOS machine (deploy ghostty config)?` — equivalent to the old `--local`
- `Deploy simple vimrc?` — equivalent to the old `--vim`
- `Install tmux via package manager?` — equivalent to the old `--tmux`
- `Install zsh via package manager?` — equivalent to the old `--zsh`

Answers are stored in `~/.config/chezmoi/chezmoi.toml`; `dot_gitconfig.tmpl`
renders `[user] name`/`email` from them, so your git identity is set up
automatically. Machine-specific or secret git settings (e.g. `[safe] directory`
entries, credentials) go in `~/.gitconfig.local`, which is `[include]`d by
`~/.gitconfig`.

`chezmoi init --apply` also runs `run_onchange_install-dependencies.sh.tmpl`,
which installs `git-delta`, `starship`, oh-my-zsh and the zsh plugins. The
script auto-detects the OS via `uname -s` and uses `brew` on macOS or
`apt-get` on Linux; on a host where everything is already present it just
skips.

### macOS vs. server / Ubuntu

The same source tree serves both, distinguished by the `macos` data flag and
the OS the install script detects. Typical answers per deployment type:

| Prompt                    | macOS (local Mac)         | Server / Ubuntu (dev-vm)   |
|---------------------------|---------------------------|----------------------------|
| `macOS machine ...`       | `true` (ghostty+aerospace) | `false` (both skipped)     |
| `Deploy simple vimrc?`   | your choice               | your choice                |
| `Install tmux ...`        | `true` (not preinstalled) | `false` (usually present)  |
| `Install zsh ...`         | `true` (not preinstalled) | `false` (usually present)  |

What differs between the two:

- **Package manager.** `run_onchange_install-dependencies.sh.tmpl` runs
  `brew install` on Darwin. On Linux it uses `sudo apt-get install` when
  passwordless sudo is available, otherwise falls back to user-space static
  binary installs into `~/.local/bin` (no root needed) for `starship` and
  `git-delta`. The OS is chosen by `uname -s`, not the `macos` flag, so it
  stays correct even if you mis-answer.
- **No-root servers.** On a Linux host without root, `starship` is installed
  via its official installer and `git-delta` via a musl static binary from
  GitHub releases — both into `~/.local/bin`, which `~/.zshrc` prepends to
  `PATH`. `zsh` and `tmux` cannot be built user-space without a compiler, so
  when `installZsh`/`installTmux` are set but no sudo is available the script
  warns and skips them (they are usually already present on servers).
- **macOS-only configs.** `~/.config/ghostty/config` (Ghostty terminal) and
  `~/.aerospace.toml` (AeroSpace tiling WM) are only deployed when `macos=true`.
  On a server both files are ignored and their target paths are never created.
- **iterm colour schemes.** `iterm/` is only useful on macOS and is imported
  manually (Settings → Profiles → Colors → Color Presets → Import). It is
  ignored by chezmoi on both platforms.
- **`coreutils`.** On macOS the install script also pulls in `coreutils`
  (for `realpath`, `gls`, etc. used by the aliases). Linux already has these.
- **Auto-zsh from bash.** `~/.bashrc` execs `zsh -l` when zsh is installed and
  the current shell isn't already zsh. This matters on servers where your
  login shell is bash (e.g. you can't `chsh` without root): SSH or terminal
  login still drops you into the managed zsh setup automatically.

### 3. (Optional) powerlevel10k

This repo ships a preconfigured `~/.config/zsh/p10k.zsh`. To reconfigure run
`p10k configure`; when asked "Apply changes to ~/.zshrc?" answer **no** (chezmoi
owns `~/.zshrc`).

A Nerd Font is recommended for the icons, see
[the powerlevel10k guide](https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k).

### 4. (Optional) iterm colour schemes

`iterm/onedark.itermcolors` and `iterm/onedarker.itermcolors` can be imported
under Settings → Profiles → Colors → Color Presets → Import.

## Day-to-day commands

```bash
chezmoi update            # pull + apply latest from the remote
chezmoi diff              # preview pending changes
chezmoi apply             # apply pending changes
chezmoi edit              # $EDITOR on the source dir
chezmoi edit ~/.zshrc     # edit a specific managed file's source
chezmoi cd                # cd into the source dir
```

To change the `macos` / `vim` / `installTmux` / `installZsh` answers after the
first init, edit `~/.config/chezmoi/chezmoi.toml` (or re-run `chezmoi init`).

## Forcing the install script to re-run

`run_onchange_install-dependencies.sh.tmpl` runs once and again only when its
content changes. Bump the `# version: 1` comment near the top to force a
re-run (the old `--force` behaviour).
