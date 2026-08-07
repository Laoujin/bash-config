Bash Config
===========

Vanilla bash + [starship](https://starship.rs) prompt.
This is a part of [Perch](https://github.com/Laoujin/perch-the-building) dotfiles.

Install
-------

```bash
git clone https://github.com/Laoujin/bash-config.git
cd bash-config
./install.sh
```

Existing files are renamed to `<name>.pre-bashconfig`, never deleted.
Re-running is a no-op.

```bash
./tests/test-fragments.sh
```

Layout
------

| File                            | Purpose                                                                           |
|---------------------------------|-----------------------------------------------------------------------------------|
| `install.sh`                    | Symlinks `.bashrc`, `.bashrc.d`, `starship.toml` into `$HOME`. Idempotent.        |
| `.bashrc`                       | Entry point. `GITHUB_TOKEN`, then sources `.bashrc.d/*.sh` in lexical order.      |
| `.bashrc.d/00-history.sh`       | History sizing and dedup.                                                         |
| `.bashrc.d/05-path.sh`          | `prepend_path` helper, reused by later fragments. `~/.local/bin`.                 |
| `.bashrc.d/10-aliases.sh`       | `ll`, `la`, `..`, `..2` … `..5`.                                                  |
| `.bashrc.d/15-cd-aliases.sh`    | Project `cd` shortcuts. `cde` opens VS Code past the `code` alias.                |
| `.bashrc.d/16-git.sh`           | git typo aliases; `pr` pushes and opens a PR.                                     |
| `.bashrc.d/17-fs.sh`            | `mkd`, `fp`, `cwd`.                                                               |
| `.bashrc.d/20-colors.sh`        | `dircolors`, colored `ls`/`grep`, `lesspipe`.                                     |
| `.bashrc.d/30-completion.sh`    | `bash-completion` if available.                                                   |
| `.bashrc.d/40-starship.sh`      | `eval $(starship init bash)`, skipped if starship isn't installed.                |
| `.bashrc.d/50-host-wsl.sh`      | WSL-only: `BROWSER=wslview`, `NODE_OPTIONS`. Self-detects via `/proc/version`.    |
| `.bashrc.d/50-host-synology.sh` | Synology-only: Entware `/opt/bin` on PATH. Self-detects via `/etc/synoinfo.conf`. |
| `.bashrc.d/60-dev.sh`           | bun, nvm, `NUGET_PACKAGES`, .NET telemetry opt-out.                               |
| `.bashrc.d/99-local.sh`         | Optional, gitignored. Per-host secrets/overrides.                                 |
| `starship.toml`                 | Prompt config. No nerd font required. Git segment comes from `git-prompt.sh`.     |
| `git-prompt.sh`                 | posh-git branch + status. One `git status` call; emits its own colour.            |
| `tests/test-fragments.sh`       | Whole suite. Plain bash, no framework.                                            |

Install starship
----------------

**WSL / generic Linux:**

```bash
curl -sS https://starship.rs/install.sh | sh
```

**Synology DSM:** install via [Entware][entware] or drop a binary manually.

```bash
# Option 1 — Entware:
opkg install starship

# Option 2 — manual (persists across DSM updates):
uname -m   # e.g. x86_64, aarch64
# Download the matching starship-<arch>-unknown-linux-musl.tar.gz from
# https://github.com/starship/starship/releases, then:
sudo tar -C /usr/local/bin -xzf starship-*-linux-musl.tar.gz
```

[entware]: https://github.com/Entware/Entware

Synology gotchas
----------------

- Confirm bash is the user's login shell — `getent passwd $USER` shows it in the last field. If not, fix in `/etc/passwd` (Synology blocks `chsh` for most accounts).
- **Don't edit `/etc/profile`** — DSM rewrites it on updates. Keep everything under `$HOME`.
- Manually-dropped binaries go in `/usr/local/bin/` (persistent). `/usr/bin/` is wiped on DSM updates.
- Uninstall oh-my-bash first: `uninstall_oh_my_bash` (or `rm -rf ~/.oh-my-bash` and clear its lines from any pre-existing `~/.bashrc`). Then run `perch deploy`.
