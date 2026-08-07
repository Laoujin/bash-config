# Linux bash migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy this repo to WSL, fold the hand-edited `~/.bashrc` into `.bashrc.d`, and port the PowerShell aliases worth keeping.

**Architecture:** A self-contained `install.sh` symlinks `.bashrc`, `.bashrc.d`, and `starship.toml` into `$HOME`. Shell config stays split into numbered fragments that each self-guard, so the same repo runs on WSL, a bare Linux box, and the Synology. A single plain-bash test script covers syntax, install behaviour, and the resulting shell.

**Tech Stack:** bash 5, starship 1.26, coreutils. No test framework — the Synology has no package manager worth relying on.

**Spec:** [`../specs/2026-08-07-linux-bash-migration-design.md`](../specs/2026-08-07-linux-bash-migration-design.md)

**Commits:** Do not commit. The user reviews and commits at the end.

---

## File Structure

| File | Responsibility | Change |
|-----------------------------------|--------------------------------------------------|--------|
| `tests/test-fragments.sh`         | Whole test suite: syntax, install, live shell     | Create |
| `install.sh`                      | Idempotent symlinking into `$HOME`                | Create |
| `.bashrc`                         | Entry point; non-interactive env above the guard  | Modify |
| `.bashrc.d/05-path.sh`            | `prepend_path` helper, `~/.local/bin`             | Create |
| `.bashrc.d/15-cd-aliases.sh`      | Project `cd` shortcuts, `cde`                     | Create |
| `.bashrc.d/16-git.sh`             | git typo aliases, `pr`                            | Create |
| `.bashrc.d/17-fs.sh`              | `mkd`, `fp`, `cwd`                                | Create |
| `.bashrc.d/50-host-wsl.sh`        | WSL-only env                                      | Modify |
| `.bashrc.d/50-host-synology.sh`   | Synology-only env                                 | Modify |
| `.bashrc.d/60-dev.sh`             | bun, nvm, .NET env                                | Create |
| `README.md`                       | Layout table, install section                     | Modify |

Fragments are split by *when they apply* (always / this host / dev tooling), not by topic, because the numeric prefix is the only ordering mechanism and load order is the thing that actually matters.

---

### Task 1: Test harness

**Files:**
- Create: `tests/test-fragments.sh`

- [ ] **Step 1: Write the harness with the first real test — syntax of every shipped shell file**

```bash
#!/usr/bin/env bash
# Plain bash, no framework: this has to run on the Synology too.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pass=0; fail=0; skipped=0

ok()      { printf 'ok    %s\n' "$1"; pass=$((pass+1)); }
no()      { printf 'FAIL  %s\n        %s\n' "$1" "${2:-}"; fail=$((fail+1)); }
skip()    { printf 'skip  %s (%s)\n' "$1" "$2"; skipped=$((skipped+1)); }

assert_eq()       { [ "$2" = "$3" ] && ok "$1" || no "$1" "expected [$2] got [$3]"; }
assert_contains() { case "$3" in *"$2"*) ok "$1";; *) no "$1" "[$3] lacks [$2]";; esac; }
assert_succeeds() { local n=$1; shift; if "$@" >/dev/null 2>&1; then ok "$n"; else no "$n" "failed: $*"; fi; }

# A throwaway HOME with the repo installed into it.
mkhome() {
  local h; h=$(mktemp -d)
  HOME="$h" "$REPO/install.sh" >/dev/null 2>&1
  printf '%s' "$h"
}

# Interactive shell in a throwaway HOME. -i is what makes .bashrc load.
in_shell() { HOME="$1" bash -i -c "$2" </dev/null 2>/dev/null; }

echo "== syntax =="
for f in "$REPO/.bashrc" "$REPO/install.sh" "$REPO"/.bashrc.d/*.sh; do
  assert_succeeds "bash -n $(basename "$f")" bash -n "$f"
done

# Load order is the only contract between fragments: 60-dev.sh calls a helper
# 05-path.sh defines. A misnumbered file shows up here as "command not found".
noise=$(bash -c 'for f in "$1"/.bashrc.d/*.sh; do . "$f"; done' _ "$REPO" 2>&1 >/dev/null)
assert_eq "fragments source clean" "" "$noise"

echo
printf 'pass %d  fail %d  skip %d\n' "$pass" "$fail" "$skipped"
[ "$fail" -eq 0 ]
```

Later tasks each append a block immediately **above** the `echo` / `printf`
summary at the bottom. The suite is cumulative — every task re-runs everything.

- [ ] **Step 2: Make it executable and run it**

Run: `chmod +x tests/test-fragments.sh && ./tests/test-fragments.sh`
Expected: FAIL — `install.sh` does not exist yet, so `bash -n install.sh` fails. The seven existing fragments and `.bashrc` pass.

Note: `mkhome` and `in_shell` are unused until Task 2. That is deliberate — they are harness, not test.

---

### Task 2: install.sh

**Files:**
- Create: `install.sh`
- Modify: `tests/test-fragments.sh`

- [ ] **Step 1: Write the failing tests**

Insert before the final `echo` / summary block:

```bash
echo
echo "== install =="

h=$(mkhome)
assert_eq "links .bashrc"       "$REPO/.bashrc"       "$(readlink -f "$h/.bashrc")"
assert_eq "links .bashrc.d"     "$REPO/.bashrc.d"     "$(readlink -f "$h/.bashrc.d")"
assert_eq "links starship.toml" "$REPO/starship.toml" "$(readlink -f "$h/.config/starship.toml")"

# Second run must not churn the links or make a backup of its own symlink.
HOME="$h" "$REPO/install.sh" >/dev/null 2>&1
assert_eq "idempotent"       "$REPO/.bashrc" "$(readlink -f "$h/.bashrc")"
assert_eq "no self-backup"   ""              "$(ls "$h"/.bashrc.pre-bashconfig 2>/dev/null)"
rm -rf "$h"

# A pre-existing real file is preserved, not clobbered.
h=$(mktemp -d)
echo "MINE" > "$h/.bashrc"
HOME="$h" "$REPO/install.sh" >/dev/null 2>&1
assert_eq "backs up real file" "MINE" "$(cat "$h/.bashrc.pre-bashconfig")"
assert_eq "then links"         "$REPO/.bashrc" "$(readlink -f "$h/.bashrc")"
rm -rf "$h"
```

- [ ] **Step 2: Run to verify it fails**

Run: `./tests/test-fragments.sh`
Expected: FAIL — `readlink -f` returns empty because no links exist.

- [ ] **Step 3: Write install.sh**

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

- [ ] **Step 4: Make executable and run**

Run: `chmod +x install.sh && ./tests/test-fragments.sh`
Expected: PASS on all syntax and install assertions.

---

### Task 3: Non-interactive GITHUB_TOKEN

**Files:**
- Modify: `.bashrc`
- Modify: `tests/test-fragments.sh`

- [ ] **Step 1: Write the failing tests**

```bash
echo
echo "== .bashrc contract =="

h=$(mkhome)

# Non-interactive shells run bun install and need the token.
if command -v gh >/dev/null && gh auth token >/dev/null 2>&1; then
  out=$(HOME="$h" bash -c '. "$HOME/.bashrc"; printf %s "${GITHUB_TOKEN:-}"')
  [ -n "$out" ] && ok "non-interactive exports GITHUB_TOKEN" \
                || no "non-interactive exports GITHUB_TOKEN" "empty"
else
  skip "non-interactive exports GITHUB_TOKEN" "gh unavailable or not authed"
fi

# ...but a non-interactive shell must not pick up the interactive fragments.
out=$(HOME="$h" bash -c '. "$HOME/.bashrc"; type ll' 2>&1)
assert_contains "guard blocks fragments" "not found" "$out"

rm -rf "$h"
```

- [ ] **Step 2: Run to verify it fails**

Run: `./tests/test-fragments.sh`
Expected: FAIL on "non-interactive exports GITHUB_TOKEN" (empty). The guard assertion already passes — that behaviour exists.

- [ ] **Step 3: Add the line to `.bashrc` above the guard**

The file becomes, in full:

```bash
# The frontends' committed .npmrc expands ${GITHUB_TOKEN} for the GitHub Packages feed, and a
# project .npmrc outranks ~/.npmrc — so the token has to come from the environment, not a
# credential file. Unset expands to empty and bun fails the install with a 401.
# Above the interactive guard on purpose: non-interactive shells run bun install too.
command -v gh >/dev/null && export GITHUB_TOKEN=$(gh auth token 2>/dev/null)

# Sourced by interactive bash shells. Bail on non-interactive.
case $- in *i*) ;; *) return;; esac

# Source ordered fragments. 50-host-* scripts self-detect their host.
if [ -d "$HOME/.bashrc.d" ]; then
  for f in "$HOME/.bashrc.d"/*.sh; do
    [ -r "$f" ] && . "$f"
  done
fi
```

- [ ] **Step 4: Run to verify it passes**

Run: `./tests/test-fragments.sh`
Expected: PASS.

---

### Task 4: PATH and dev-runtime fragments

**Files:**
- Create: `.bashrc.d/05-path.sh`
- Create: `.bashrc.d/60-dev.sh`
- Modify: `.bashrc.d/50-host-wsl.sh`
- Modify: `.bashrc.d/50-host-synology.sh`
- Modify: `tests/test-fragments.sh`

- [ ] **Step 1: Write the failing tests**

```bash
echo
echo "== path and dev env =="

h=$(mkhome)
mkdir -p "$h/.local/bin" "$h/.bun/bin"

path=$(in_shell "$h" 'printf %s "$PATH"')
case ":$path:" in
  *":$h/.bun/bin:"*) ok "bun bin on PATH";;
  *)                 no "bun bin on PATH" "$path";;
esac
bun_pos=${path%%$h/.bun/bin*};   bun_pos=${#bun_pos}
loc_pos=${path%%$h/.local/bin*}; loc_pos=${#loc_pos}
[ "$bun_pos" -lt "$loc_pos" ] && ok "bun precedes .local/bin" \
                              || no "bun precedes .local/bin" "$path"

assert_eq "NUGET_PACKAGES" "$h/.nuget/packages" "$(in_shell "$h" 'printf %s "$NUGET_PACKAGES"')"
assert_eq "telemetry optout" "1"                "$(in_shell "$h" 'printf %s "$DOTNET_CLI_TELEMETRY_OPTOUT"')"
assert_eq "prepend_path survives" "function"    "$(in_shell "$h" 'printf %s "$(type -t prepend_path)"')"

# Synology fragment must be inert on a non-Synology host.
out=$(bash -c ". '$REPO/.bashrc.d/50-host-synology.sh'; printf %s \"\$PATH\"" 2>&1)
case "$out" in *"/opt/bin"*) no "synology guard" "leaked /opt/bin";; *) ok "synology guard";; esac

rm -rf "$h"
```

- [ ] **Step 2: Run to verify it fails**

Run: `./tests/test-fragments.sh`
Expected: FAIL on `NUGET_PACKAGES`, `telemetry optout`, and `prepend_path survives`. The bun assertions pass by accident today (`50-host-wsl.sh` still sets them) — that is fine, they must keep passing after the move.

- [ ] **Step 3: Create `.bashrc.d/05-path.sh`**

```bash
# Not unset after use: 50-host-* and 60-dev.sh reuse it.
prepend_path() {
  case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH";; esac
}

prepend_path "$HOME/.local/bin"
```

- [ ] **Step 4: Create `.bashrc.d/60-dev.sh`**

```bash
export BUN_INSTALL="$HOME/.bun"
[ -d "$BUN_INSTALL/bin" ] && prepend_path "$BUN_INSTALL/bin"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

export NUGET_PACKAGES="$HOME/.nuget/packages"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
```

- [ ] **Step 5: Replace `.bashrc.d/50-host-wsl.sh` in full**

```bash
grep -qi microsoft /proc/version 2>/dev/null || return 0

export BROWSER=wslview

# V8 sizes each heap from total VM RAM, so concurrent node processes
# collectively overcommit the WSL memory cap and get OOM-killed.
export NODE_OPTIONS=--max-old-space-size=4096
```

- [ ] **Step 6: Replace `.bashrc.d/50-host-synology.sh` in full**

```bash
[ -f /etc/synoinfo.conf ] || return 0

# Entware (opkg) — optional; safe if absent.
[ -d /opt/bin ]  && prepend_path /opt/bin
[ -d /opt/sbin ] && prepend_path /opt/sbin

# DSM sometimes leaves TERM empty over SSH, breaking readline/colors.
[ -z "$TERM" ] && export TERM=xterm-256color
```

- [ ] **Step 7: Run to verify it passes**

Run: `./tests/test-fragments.sh`
Expected: PASS, including the bun assertions that now come from `60-dev.sh`.

---

### Task 5: cd aliases

**Files:**
- Create: `.bashrc.d/15-cd-aliases.sh`
- Modify: `tests/test-fragments.sh`

- [ ] **Step 1: Write the failing tests**

```bash
echo
echo "== cd aliases =="

h=$(mkhome)

for a in code projects itenium ideas goca home pirateflix courses scout atlas adw \
         bliki userscripts sangu obsidian confac eli forge ttc perch; do
  out=$(in_shell "$h" "alias $a" 2>&1)
  assert_contains "alias $a" "cd " "$out"
done

assert_eq "cde is a function" "function" "$(in_shell "$h" 'printf %s "$(type -t cde)"')"

# cde must reach the real binary past the `code` alias.
if command -v code >/dev/null; then
  out=$(in_shell "$h" 'type -a cde; command -v code')
  assert_contains "cde reaches VS Code" "code" "$out"
else
  skip "cde reaches VS Code" "code not installed"
fi

# Targets are checked against the live filesystem, not the throwaway HOME.
if [ -d "$HOME/code" ]; then
  missing=$(grep -o '"\$HOME/code[^"]*"' "$REPO/.bashrc.d/15-cd-aliases.sh" \
    | tr -d '"' | while read -r p; do
        d=${p/\$HOME/$HOME}; [ -d "$d" ] || echo "$d"
      done)
  assert_eq "all cd targets exist" "" "$missing"
else
  skip "all cd targets exist" "\$HOME/code absent"
fi

rm -rf "$h"
```

- [ ] **Step 2: Run to verify it fails**

Run: `./tests/test-fragments.sh`
Expected: FAIL — twenty `alias X` assertions plus `cde is a function`.

- [ ] **Step 3: Create `.bashrc.d/15-cd-aliases.sh`**

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

- [ ] **Step 4: Run to verify it passes**

Run: `./tests/test-fragments.sh`
Expected: PASS.

---

### Task 6: git aliases

**Files:**
- Create: `.bashrc.d/16-git.sh`
- Modify: `tests/test-fragments.sh`

- [ ] **Step 1: Write the failing tests**

```bash
echo
echo "== git =="

h=$(mkhome)
for a in gt gut gti got guit giut giot goit igt; do
  assert_contains "alias $a" "git" "$(in_shell "$h" "alias $a" 2>&1)"
done
assert_eq "pr is a function" "function" "$(in_shell "$h" 'printf %s "$(type -t pr)"')"
rm -rf "$h"
```

- [ ] **Step 2: Run to verify it fails**

Run: `./tests/test-fragments.sh`
Expected: FAIL on all nine aliases and `pr is a function`.

- [ ] **Step 3: Create `.bashrc.d/16-git.sh`**

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

- [ ] **Step 4: Run to verify it passes**

Run: `./tests/test-fragments.sh`
Expected: PASS.

---

### Task 7: filesystem helpers

**Files:**
- Create: `.bashrc.d/17-fs.sh`
- Modify: `tests/test-fragments.sh`

- [ ] **Step 1: Write the failing tests**

```bash
echo
echo "== fs helpers =="

h=$(mkhome)
for fn in mkd fp cwd; do
  assert_eq "$fn is a function" "function" "$(in_shell "$h" "printf %s \"\$(type -t $fn)\"")"
done

# mkd creates nested dirs and lands in them.
t=$(mktemp -d)
out=$(in_shell "$h" "cd '$t' && mkd a/b/c && printf %s \"\$PWD\"")
assert_eq "mkd creates and enters" "$t/a/b/c" "$out"
rm -rf "$t"

# fp filters $PATH case-insensitively, one entry per line.
# Append rather than replace: fp calls grep, which needs a working PATH.
out=$(in_shell "$h" 'PATH="$PATH:/ZZfp/lib"; fp zzfp')
assert_eq "fp filters PATH" "/ZZfp/lib" "$out"

rm -rf "$h"
```

`cwd` is asserted to exist but not invoked — it writes to the system clipboard, which a test must not clobber.

- [ ] **Step 2: Run to verify it fails**

Run: `./tests/test-fragments.sh`
Expected: FAIL on the three function assertions plus the `mkd` and `fp` behaviour tests.

- [ ] **Step 3: Create `.bashrc.d/17-fs.sh`**

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

- [ ] **Step 4: Run to verify it passes**

Run: `./tests/test-fragments.sh`
Expected: PASS. Full suite green.

---

### Task 8: Deploy to the real `$HOME`

**Files:** none — this runs the tool against the live machine.

- [ ] **Step 1: Confirm the whole suite is green first**

Run: `./tests/test-fragments.sh`
Expected: `fail 0`.

- [ ] **Step 2: Install**

Run: `./install.sh`
Expected output includes `saved /home/wouter/.bashrc.pre-bashconfig` and three `link` lines.

- [ ] **Step 3: Verify the live shell**

Run:
```bash
bash -i -c 'type ll gt mkd cde; alias confac; printf "%s\n" "$NUGET_PACKAGES" "$NODE_OPTIONS" "$BROWSER"' </dev/null
```
Expected: every name resolves; `NUGET_PACKAGES` is `/home/wouter/.nuget/packages`, `NODE_OPTIONS` is `--max-old-space-size=4096`, `BROWSER` is `wslview`.

- [ ] **Step 4: Verify the prompt renders**

Run: `cd ~/code/projects/confac/confac && bash -i -c 'starship module directory' </dev/null`
Expected: `confac`.

- [ ] **Step 5: Diff the backup against what was ported**

Run: `diff <(sort ~/.bashrc.pre-bashconfig) <(sort ~/.bashrc)`
Expected: every removed line maps to a row in the spec's disposition table. Read the diff — do not skim it. This is the last chance to catch a dropped line.

---

### Task 9: README

**Files:**
- Modify: `README.md`

Not in the spec, but the README's layout table enumerates fragments and would ship stale.

- [ ] **Step 1: Add the four new fragments to the layout table**

Insert rows in numeric order:

```markdown
| `.bashrc.d/05-path.sh`        | `prepend_path` helper, `~/.local/bin` on PATH.                         |
| `.bashrc.d/15-cd-aliases.sh`  | Project `cd` shortcuts. `cde` opens VS Code.                           |
| `.bashrc.d/16-git.sh`         | git typo aliases, `pr` to push and open a PR.                          |
| `.bashrc.d/60-dev.sh`         | bun, nvm, `NUGET_PACKAGES`, .NET telemetry opt-out.                    |
| `.bashrc.d/17-fs.sh`          | `mkd`, `fp`, `cwd`.                                                    |
```

- [ ] **Step 2: Correct the `50-host-wsl.sh` row**

It currently claims bun and nvm. Replace its description with:

```markdown
| `.bashrc.d/50-host-wsl.sh`    | WSL-only: `BROWSER=wslview`, `NODE_OPTIONS`. Self-detects via `/proc/version`. |
```

- [ ] **Step 3: Add an Install section above "Install starship"**

````markdown
Install
-------

```bash
git clone https://github.com/Laoujin/bash-config.git
cd bash-config
./install.sh
```

Existing files are renamed to `<name>.pre-bashconfig`, never deleted. Re-running
is a no-op.

Tests: `./tests/test-fragments.sh`
````

- [ ] **Step 4: Verify the tests still pass and stop**

Run: `./tests/test-fragments.sh`
Expected: `fail 0`. Leave everything uncommitted for review.
