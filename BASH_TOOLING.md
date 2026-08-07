CLI tooling shortlist
=====================

Nothing here is installed. Star counts fetched 2026-08-07.

Top tier
--------

| Tool          | Stars | Replaces / adds                                                                                                                                                               |
|---------------|-------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [fzf][fzf]    | 82.4k | Fuzzy Ctrl+R, Ctrl+T, and a filter to pipe anything into. The one every other tool composes with.                                                                             |
| [lazygit][lg] | 81.1k | TUI for staging hunks, interactive rebase, reflog. Faster than a GUI for `git add -p` work.                                                                                   |
| [ripgrep][rg] | 67.1k | grep, but respects `.gitignore` and is ~10× faster. What VS Code searches with.                                                                                               |
| [bat][bat]    | 60.1k | `cat` with syntax highlighting and a git gutter. Also a pager for `--help`.                                                                                                   |
| [fd][fd]      | 44.0k | `find` with sane syntax, gitignore-aware.                                                                                                                                     |
| [zoxide][zo]  | 38.5k | `z confac` jumps to the dir visited most. Learns; kills most of `15-cd-aliases.sh`.                                                                                           |
| [jq][jq]      | 35.4k | JSON.                                                                                                                                                                         |
| [delta][dl]   | 31.7k | Word-level diff highlighting inside git. Drop-in via `core.pager`.                                                                                                            |
| [atuin][at]   | 31.1k | SQLite-backed history: full-text search, per-directory recall, dedup, sync across WSL + Synology. Supersedes the `HISTIGNORE` fiddling in [SHOPT_CONFIG.md](SHOPT_CONFIG.md). |

[fzf]: https://github.com/junegunn/fzf
[lg]: https://github.com/jesseduffield/lazygit
[rg]: https://github.com/BurntSushi/ripgrep
[bat]: https://github.com/sharkdp/bat
[fd]: https://github.com/sharkdp/fd
[zo]: https://github.com/ajeetdsouza/zoxide
[jq]: https://github.com/jqlang/jq
[dl]: https://github.com/dandavison/delta
[at]: https://github.com/atuinsh/atuin

Strong second tier
------------------

| Tool             | Stars | Replaces / adds                                                                                              |
|------------------|-------|--------------------------------------------------------------------------------------------------------------|
| [tldr][tl]       | 63.3k | Man pages replaced by five examples.                                                                         |
| [dive][di]       | 54.4k | Image-layer inspector: shows what bloated the Dockerfile.                                                    |
| [lazydocker][ld] | 52.3k | Container TUI.                                                                                               |
| [just][ju]       | 35.2k | Make without the tab and phony baggage. Project task runner.                                                 |
| [btop][bt]       | 33.9k | htop, prettier, with GPU and net.                                                                            |
| [mise][mi]       | 32.0k | One tool for node/python/dotnet/bun versions plus per-project env. Retires `nvm` and its shell-startup cost. |
| [eza][ez]        | 22.9k | `ls` with git status, tree mode, icons.                                                                      |
| [ast-grep][sg]   | 15.4k | Structural search/rewrite by syntax tree — `$A?.$B` across a TS codebase. Regex can't do this.               |
| [duf][df]        | 15.2k | `df` readable at a glance.                                                                                   |
| [dust][du]       | 12.1k | `du` readable at a glance.                                                                                   |
| [xh][xh]         |  8.0k | httpie's ergonomics, Rust speed. `xh POST :5000/api key=value`.                                              |
| [watchexec][we]  |  7.1k | Re-run a command on file change, language-agnostic.                                                          |

[tl]: https://github.com/tldr-pages/tldr
[di]: https://github.com/wagoodman/dive
[ld]: https://github.com/jesseduffield/lazydocker
[bt]: https://github.com/aristocratos/btop
[mi]: https://github.com/jdx/mise
[ju]: https://github.com/casey/just
[ez]: https://github.com/eza-community/eza
[sg]: https://github.com/ast-grep/ast-grep
[df]: https://github.com/muesli/duf
[du]: https://github.com/bootandy/dust
[xh]: https://github.com/ducaale/xh
[we]: https://github.com/watchexec/watchexec

Situational but excellent
-------------------------

| Tool             | Stars | For                                                                      |
|------------------|-------|--------------------------------------------------------------------------|
| [yazi][ya]       | 41.1k | File manager TUI, image previews, fzf-integrated.                        |
| [croc][cr]       | 39.5k | Send a file machine-to-machine with a code phrase.                       |
| [restic][re]     | 35.4k | Deduplicating encrypted backups. Synology-relevant.                      |
| [zellij][ze]     | 34.8k | tmux with discoverable keybindings and persistent sessions over SSH.     |
| [hyperfine][hf]  | 28.6k | Statistically honest benchmarking of two commands.                       |
| [glow][gl]       | 26.7k | Render markdown in the terminal.                                         |
| [difftastic][dt] | 25.7k | Syntax-aware diff: ignores pure reformatting.                            |
| [yq][yq]         | 15.8k | jq for YAML — `manifest.yaml`, compose files.                            |
| [direnv][de]     | 15.3k | Per-directory env vars on `cd`. Overlaps with mise.                      |
| [gron][gr]       | 14.5k | Flattens JSON into greppable lines; `gron -u` puts them back.            |
| [lnav][ln]       | 10.5k | Log file TUI with SQL queries over log lines. Local counterpart to Loki. |

[ya]: https://github.com/sxyazi/yazi
[cr]: https://github.com/schollz/croc
[re]: https://github.com/restic/restic
[ze]: https://github.com/zellij-org/zellij
[hf]: https://github.com/sharkdp/hyperfine
[gl]: https://github.com/charmbracelet/glow
[dt]: https://github.com/Wilfred/difftastic
[yq]: https://github.com/mikefarah/yq
[de]: https://github.com/direnv/direnv
[gr]: https://github.com/tomnomnom/gron
[ln]: https://github.com/tstack/lnav

Installing
----------

Nearly all of these are single static Go/Rust binaries. Where Entware's package list comes up
short on the Synology, drop the release tarball into `/usr/local/bin` — same approach the
[README](README.md) documents for starship.

`fzf`, `atuin`, `zoxide`, `mise` and `direnv` need shell wiring, and each one costs startup time.
They belong in one fragment behind `command -v` guards, the way `40-starship.sh` does it.
