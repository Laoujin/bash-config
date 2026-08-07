# Linux bash migration

Deploy this repo to WSL, fold the hand-edited `~/.bashrc` into `.bashrc.d`,
and port the PowerShell functionality worth keeping.

## Context

WSL is the daily driver today; a native Linux box follows later. Windows and
the PowerShell config keep working in the meantime, so this is a port, not a
cutover. Every design choice below favours a fragment that also runs on a bare
Linux box or the Synology over one that assumes WSL.

Starting state:

| Thing               | State                                                     |
|---------------------|-----------------------------------------------------------|
| `bash/` submodule   | Complete, never deployed                                  |
| `~/.bashrc.d`       | Absent                                                    |
| `~/.bashrc`         | Stock Ubuntu plus eight hand edits                        |
| `~/.bash_profile`   | Absent — `~/.profile` is stock and sources `~/.bashrc`    |
| `starship`          | Installed, 1.26.0, `/usr/local/bin/starship`              |

Perch is not used for installation. It is unfinished, and this repo is a
submodule with its own remote that has to stand alone on a machine where
`perch-config` and the gallery are not checked out. `manifest.yaml` stays as
written so both paths work if Perch ever ships.

## Install

`install.sh` at the repo root. Idempotent, coreutils only.

```bash
#!/usr/bin/env bash
set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local from="$src/$1" to="$2"
  mkdir -p "$(dirname "$to")"
  if [ -L "$to" ]; then
    [ "$(readlink -f "$to")" = "$from" ] && { echo "ok    $to"; return; }
    rm "$to"
  elif [ -e "$to" ]; then
    mv "$to" "$to.pre-bashconfig"
    echo "saved $to.pre-bashconfig"
  fi
  ln -s "$from" "$to"
  echo "link  $to -> $from"
}

link .bashrc       "$HOME/.bashrc"
link .bashrc.d     "$HOME/.bashrc.d"
link starship.toml "$HOME/.config/starship.toml"

command -v starship >/dev/null || echo "warn  starship not installed - see README"
```

A correct symlink is a no-op, a wrong one is replaced, and a real file is
renamed to `<name>.pre-bashconfig` rather than deleted. The first run turns the
current `~/.bashrc` into `~/.bashrc.pre-bashconfig`.

`~/.profile` is not touched.

## Reconciling `~/.bashrc`

### `.bashrc`

One line is added above the interactive guard:

```bash
# The frontends' committed .npmrc expands ${GITHUB_TOKEN} for the GitHub Packages feed, and a
# project .npmrc outranks ~/.npmrc — so the token has to come from the environment, not a
# credential file. Unset expands to empty and bun fails the install with a 401.
# Above the interactive guard on purpose: non-interactive shells run bun install too.
command -v gh >/dev/null && export GITHUB_TOKEN=$(gh auth token 2>/dev/null)
```

It cannot live in `.bashrc.d`, because the guard returns before the fragment
loop runs. The rest of `.bashrc` is unchanged.

### `05-path.sh` (new)

```bash
# Not unset after use: 50-host-* and 60-dev.sh reuse it.
prepend_path() {
  case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH";; esac
}

prepend_path "$HOME/.local/bin"
```

### `60-dev.sh` (new)

```bash
export BUN_INSTALL="$HOME/.bun"
[ -d "$BUN_INSTALL/bin" ] && prepend_path "$BUN_INSTALL/bin"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

export NUGET_PACKAGES="$HOME/.nuget/packages"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
```

bun and nvm leave `50-host-wsl.sh` because nothing about them is WSL-specific.
Both guards are already existence checks, so the fragment is inert where the
tools are absent.

### `50-host-wsl.sh` (edited)

```bash
grep -qi microsoft /proc/version 2>/dev/null || return 0

export BROWSER=wslview

# V8 sizes each heap from total VM RAM, so concurrent node processes
# collectively overcommit the WSL memory cap and get OOM-killed.
export NODE_OPTIONS=--max-old-space-size=4096
```

### `50-host-synology.sh` (edited)

Loses its local `prepend_path` definition and uses the one from `05-path.sh`.
Body otherwise unchanged.

### Disposition

Every line of the current `~/.bashrc` is accounted for:

| Line(s) | Content                                    | Fate                                                    |
|---------|--------------------------------------------|---------------------------------------------------------|
| 9       | `GITHUB_TOKEN`                             | `.bashrc`, above the guard                              |
| 19–30   | history, `checkwinsize`                    | Covered by `00-history.sh`, at 10000/20000 not 1000/2000 |
| 37      | `lesspipe`                                 | Covered by `20-colors.sh`                               |
| 40–79   | `debian_chroot`, `PS1`, xterm title        | Dropped — starship owns the prompt                      |
| 82–91   | `dircolors`, `ls`/`grep` colours           | Covered by `20-colors.sh`                               |
| 97–99   | `ll`, `la`, `l`                            | Covered by `10-aliases.sh`                              |
| 103     | `alert`                                    | Dropped — `notify-send` is not installed                |
| 110–112 | `.bash_aliases` hook                       | Dropped — `.bashrc.d` supersedes it                     |
| 117–123 | bash-completion                            | Covered by `30-completion.sh`                           |
| 124     | `$HOME/.local/bin`                         | `05-path.sh`                                            |
| 127–132 | bun, nvm                                   | `60-dev.sh`                                             |
| 134     | `NUGET_PACKAGES`                           | `60-dev.sh`                                             |
| 137     | `DOTNET_CLI_TELEMETRY_OPTOUT`              | `60-dev.sh`                                             |
| 139–141 | `NODE_OPTIONS`                             | `50-host-wsl.sh`                                        |

PATH order is preserved: `.local/bin` is prepended at 05 and bun at 60, so bun
still wins.

`$HOME/.dotnet/tools` is deliberately not added. It is not on PATH today and
nothing needs it now that Perch is out.

## Ported PowerShell functionality

Ported: git typo aliases, `pr`, `mkd`, `cwd`, `fp`, and the `cd` aliases.

Dropped, with reasons:

| PowerShell                               | Reason                                    |
|------------------------------------------|-------------------------------------------|
| `..`, `...`, `....`                       | Already in `10-aliases.sh`                |
| `touch`, `rmd`, `fs`, `Download-File`     | Native as `touch`, `rm -rf`, `du -sh`, `curl -O` |
| `mdp`, `Edit-Hosts`, `Empty-RecycleBins`  | Windows-only                              |
| `dev` (`wt split-pane`)                   | Windows Terminal only                     |
| `se`, `re`, `ap`, `delp`                  | Windows registry                          |
| `d`, `dc`, `dcub`, `cleanbins`, `bejs*`   | Not wanted                                |
| Prompt shrinkers                          | See "Prompt" below                        |

### Name collisions

Two of the twenty-one new names shadow existing commands. Both are kept:

| Name   | Shadows                                            | Resolution                              |
|--------|----------------------------------------------------|-----------------------------------------|
| `code` | `/mnt/c/Program Files/Microsoft VS Code/bin/code`   | `cd` wins; VS Code becomes `cde`        |
| `pr`   | `/usr/bin/pr`                                      | PR-create wins; `command pr` still works |

The remaining nineteen names are unused in the current shell.

### `15-cd-aliases.sh` (new)

Nineteen `cd` aliases rooted at `$HOME/code`, plus `perch` on the Windows side.
`$HOME/code` is the WSL symlink to the Dropbox tree today and becomes a real
directory after the migration, so those paths need no rewrite. All twenty
targets were verified to exist.

```bash
alias code='cd "$HOME/code"'
alias projects='cd "$HOME/code/projects"'
alias itenium='cd "$HOME/code/itenium"'
alias ideas='cd "$HOME/code/_todo-projects"'
alias goca='cd "$HOME/code/projects/goca/mongo-replication"'
alias home='cd "$HOME/code/_personal/Home"'
alias pirateflix='cd "$HOME/code/_personal/sangu-be/htpc-site"'
alias courses='cd "$HOME/code/courses"'
alias scout='cd "$HOME/code/projects/Scout+Atlas/scout"'
alias atlas='cd "$HOME/code/projects/Scout+Atlas/atlas"'
alias adw='cd "$HOME/code/itenium-projects/ADW/ADW"'

alias bliki='cd "$HOME/code/bliki/blog-posts-new"'
alias userscripts='cd "$HOME/code/_personal/windows/UserScriptCollection"'
alias sangu='cd "$HOME/code/_personal/sangu-be"'
alias obsidian='cd "$HOME/code/_personal/Obsidian"'

alias confac='cd "$HOME/code/projects/confac/confac"'
alias eli='cd "$HOME/code/projects/stockoma/stockoma"'
alias forge='cd "$HOME/code/projects/Itenium.Forge"'
alias ttc='cd "$HOME/code/projects/ttc/ttc-aalst"'

# Windows-side; needs a new path once this repo lives on Linux.
alias perch='cd /mnt/c/tools/Perch/perch-config'

# The `code` alias above shadows the VS Code CLI. `command` bypasses aliases.
cde() { command code "${@:-.}"; }
```

`mike` and `dotfiles` are dropped from the PowerShell list: `/mnt/c/tools/Mi-Ke`
and `/mnt/c/tools/dotfiles` no longer exist.

`projects` points at `~/code/projects`, not the native `~/projects`. The two
trees both contain an `ADW` and an `Itenium.Forge`, so `adw` and `forge` are a
standing confusion risk until the migration collapses them.

### `16-git.sh` (new)

```bash
alias gt=git
alias gut=git
alias gti=git
alias got=git
alias guit=git
alias giut=git
alias giot=git
alias goit=git
alias igt=git

pr() { git push -u origin HEAD && gh pr create --web --base "${1:-main}"; }
```

The PowerShell `pr` hand-built compare URLs for GitHub and Azure DevOps.
`gh pr create --web` covers GitHub only; the Azure DevOps branch is dropped.

### `17-fs.sh` (new)

```bash
mkd() { mkdir -p "$1" && cd "$1"; }

fp() { printf '%s\n' "${PATH//:/$'\n'}" | grep -i -- "$1"; }

cwd() {
  if   command -v wl-copy  >/dev/null; then printf '%s' "$PWD" | wl-copy
  elif command -v xclip    >/dev/null; then printf '%s' "$PWD" | xclip -selection clipboard
  elif command -v clip.exe >/dev/null; then printf '%s' "$PWD" | clip.exe
  else echo "cwd: no clipboard tool" >&2; return 1
  fi
}
```

`cwd` probes native tools first, so the WSL fallback falls away by itself on a
real Linux box. Only `clip.exe` is present today.

## Prompt

`starship.toml` is unchanged. No `[directory.substitutions]` block is added.

The PowerShell shrinkers existed because posh-git printed the full
`C:\Users\Woute\Dropbox\Personal\Programming\UnixCode\...` path. Both causes of
that length are gone: `truncate_to_repo = true` collapses every in-repo path to
repo-relative, and `$HOME/code` replaced the Windows prefix. Rendered against
the real config, nothing exceeds three components:

| `cd` to                                       | Renders as             |
|-----------------------------------------------|------------------------|
| `~/code`                                      | `~/code`               |
| `~/code/projects`                             | `~/code/projects`      |
| `~/code/_personal`                            | `~/code/_personal`     |
| `~/code/_todo-projects`                       | `_todo-projects`       |
| `~/code/projects/confac/confac`               | `confac`               |
| `~/code/projects/Scout+Atlas/scout`           | `scout`                |
| `~/code/projects/confac/confac/backend/logs`  | `confac/backend/logs`  |
| `~/code/_personal/sangu-be/htpc-site`         | `htpc-site`            |

A substitutions block would fire on `~/code/projects` and nowhere else.

## Tests

`tests/test-fragments.sh`. Plain bash with an assert helper, no framework, so
it runs on the Synology too. Written before the fragments and expected to fail
first.

Integration cases build a throwaway `HOME`, run `install.sh` against it, and
launch a real shell there. Unit cases source a fragment directly.

| Case                    | Assertion                                                             |
|-------------------------|-----------------------------------------------------------------------|
| Syntax                  | `bash -n` passes on `.bashrc`, `install.sh`, and every `.bashrc.d/*.sh` |
| Chain sourcing          | Sourcing every `.bashrc.d/*.sh` in lexical order emits nothing on stderr |
| Install idempotence     | Two `install.sh` runs leave the same three symlinks and one backup    |
| Install backup          | A pre-existing real `~/.bashrc` survives as `~/.bashrc.pre-bashconfig` |
| Non-interactive token   | `bash -c '. ~/.bashrc; echo $GITHUB_TOKEN'` is non-empty when `gh` exists, skipped otherwise |
| Interactive guard       | A non-interactive shell defines no aliases                            |
| Aliases present         | `bash -i` resolves `ll`, `gt`, `code`, `confac`                       |
| Functions present       | `bash -i` resolves `mkd`, `fp`, `cwd`, `cde`, `pr`                    |
| `cd` targets exist      | Every `$HOME/code` path in `15-cd-aliases.sh` is a directory          |
| `cde` reaches VS Code   | `cde` resolves past the `code` alias to a real binary                 |
| PATH order              | With both bin dirs stubbed in the throwaway `HOME`, bun's precedes `.local/bin` |
| Host guards             | `50-host-synology.sh` is a no-op without `/etc/synoinfo.conf`         |

Two cases depend on the machine rather than the repo and skip rather than fail:
the `cd`-target check when `$HOME/code` is absent, and the token check when
`gh` is missing. The PATH-order case creates its own `bin` directories inside
the throwaway `HOME`, since `60-dev.sh` only prepends paths that exist.

## Out of scope

- Installing starship. The README already covers WSL and Synology.
- Migrating the Dropbox tree off `/mnt/c` onto the Linux filesystem.
- Any change to the `powershell` module. It stays as-is until Windows goes.
- Making Perch work on Linux.
