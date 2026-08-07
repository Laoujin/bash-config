#!/usr/bin/env bash
# Plain bash, no framework: this has to run on the Synology too.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_HOME="$HOME"
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
  # /etc/bash.bashrc prints a sudo hint unless one of these exists, and it
  # would land in the middle of every in_shell capture.
  touch "$h/.hushlogin"
  printf '%s' "$h"
}

# Interactive shell in a throwaway HOME. -i is what makes .bashrc load.
# env -i, because the runner's own shell exports half the variables under test.
in_shell() {
  env -i HOME="$1" TERM=dumb PATH=/usr/local/bin:/usr/bin:/bin \
    bash -i -c "$2" </dev/null 2>/dev/null
}

echo "== syntax =="
for f in "$REPO/.bashrc" "$REPO/install.sh" "$REPO"/.bashrc.d/*.sh; do
  assert_succeeds "bash -n $(basename "$f")" bash -n "$f"
done

# Load order is the only contract between fragments: 60-dev.sh calls a helper
# 05-path.sh defines. A misnumbered file shows up here as "command not found".
noise=$(bash -c 'for f in "$1"/.bashrc.d/*.sh; do . "$f"; done' _ "$REPO" 2>&1 >/dev/null)
assert_eq "fragments source clean" "" "$noise"

echo
echo "== install =="

h=$(mkhome)
assert_eq "links .bashrc"       "$REPO/.bashrc"       "$(readlink -f "$h/.bashrc")"
assert_eq "links .bashrc.d"     "$REPO/.bashrc.d"     "$(readlink -f "$h/.bashrc.d")"
assert_eq "links starship.toml" "$REPO/starship.toml" "$(readlink -f "$h/.config/starship.toml")"
assert_eq "links git-prompt.sh" "$REPO/git-prompt.sh" "$(readlink -f "$h/.config/starship-git-prompt.sh")"

# Second run must not churn the links or make a backup of its own symlink.
HOME="$h" "$REPO/install.sh" >/dev/null 2>&1
assert_eq "idempotent"     "$REPO/.bashrc" "$(readlink -f "$h/.bashrc")"
assert_eq "no self-backup" ""              "$(ls "$h"/.bashrc.pre-bashconfig 2>/dev/null)"
rm -rf "$h"

# A pre-existing real file is preserved, not clobbered.
h=$(mktemp -d)
echo "MINE" > "$h/.bashrc"
HOME="$h" "$REPO/install.sh" >/dev/null 2>&1
assert_eq "backs up real file" "MINE"          "$(cat "$h/.bashrc.pre-bashconfig")"
assert_eq "then links"         "$REPO/.bashrc" "$(readlink -f "$h/.bashrc")"
rm -rf "$h"

echo
echo "== .bashrc contract =="

h=$(mkhome)

# Non-interactive shells run bun install and need the token.
# env -u: the runner's own shell already exports it, which would fake a pass.
# GH_CONFIG_DIR: the throwaway HOME hides gh's credentials, and gh with no
# GITHUB_TOKEN to echo back would then return nothing.
if command -v gh >/dev/null && gh auth token >/dev/null 2>&1; then
  out=$(env -u GITHUB_TOKEN HOME="$h" GH_CONFIG_DIR="${GH_CONFIG_DIR:-$REAL_HOME/.config/gh}" \
        bash -c '. "$HOME/.bashrc"; printf %s "${GITHUB_TOKEN:-}"')
  [ -n "$out" ] && ok "non-interactive exports GITHUB_TOKEN" \
                || no "non-interactive exports GITHUB_TOKEN" "empty"
else
  skip "non-interactive exports GITHUB_TOKEN" "gh unavailable or not authed"
fi

# ...but a non-interactive shell must not pick up the interactive fragments.
out=$(HOME="$h" bash -c '. "$HOME/.bashrc"; type ll' 2>&1)
assert_contains "guard blocks fragments" "not found" "$out"

rm -rf "$h"

echo
echo "== path and dev env =="

h=$(mkhome)
# 60-dev.sh only prepends paths that exist, so the test has to create them.
mkdir -p "$h/.local/bin" "$h/.bun/bin"

path=$(in_shell "$h" 'printf %s "$PATH"')
case ":$path:" in
  *":$h/.bun/bin:"*) ok "bun bin on PATH";;
  *)                 no "bun bin on PATH" "$path";;
esac
bun_pos=${path%%"$h"/.bun/bin*};   bun_pos=${#bun_pos}
loc_pos=${path%%"$h"/.local/bin*}; loc_pos=${#loc_pos}
[ "$bun_pos" -lt "$loc_pos" ] && ok "bun precedes .local/bin" \
                              || no "bun precedes .local/bin" "$path"

assert_eq "NUGET_PACKAGES"        "$h/.nuget/packages" "$(in_shell "$h" 'printf %s "$NUGET_PACKAGES"')"
assert_eq "telemetry optout"      "1"                  "$(in_shell "$h" 'printf %s "$DOTNET_CLI_TELEMETRY_OPTOUT"')"
assert_eq "prepend_path survives" "function"           "$(in_shell "$h" 'printf %s "$(type -t prepend_path)"')"

# Synology fragment must be inert on a non-Synology host.
out=$(bash -c ". '$REPO/.bashrc.d/50-host-synology.sh'; printf %s \"\$PATH\"" 2>&1)
case "$out" in *"/opt/bin"*) no "synology guard" "leaked /opt/bin";; *) ok "synology guard";; esac

rm -rf "$h"

echo
echo "== cd aliases =="

h=$(mkhome)

for a in code projects itenium ideas goca home pirateflix courses scout atlas adw \
         bliki userscripts sangu obsidian confac eli forge ttc perch; do
  assert_contains "alias $a" "cd " "$(in_shell "$h" "alias $a" 2>&1)"
done

assert_eq "cde is a function" "function" "$(in_shell "$h" 'printf %s "$(type -t cde)"')"

# cde must reach the real binary past the `code` alias.
if command -v code >/dev/null; then
  assert_contains "cde reaches VS Code" "code" "$(in_shell "$h" 'type -a cde')"
else
  skip "cde reaches VS Code" "code not installed"
fi

# Targets are checked against the live filesystem, not the throwaway HOME.
if [ -d "$REAL_HOME/code" ]; then
  missing=$(grep -o '"\$HOME/code[^"]*"' "$REPO/.bashrc.d/15-cd-aliases.sh" \
    | tr -d '"' | while read -r p; do
        d=${p/\$HOME/$REAL_HOME}; [ -d "$d" ] || echo "$d"
      done)
  assert_eq "all cd targets exist" "" "$missing"
else
  skip "all cd targets exist" "\$HOME/code absent"
fi

rm -rf "$h"

echo
echo "== git =="

h=$(mkhome)
for a in gt gut gti got guit giut giot goit igt; do
  assert_contains "alias $a" "git" "$(in_shell "$h" "alias $a" 2>&1)"
done
assert_eq "pr is a function" "function" "$(in_shell "$h" 'printf %s "$(type -t pr)"')"
rm -rf "$h"

echo
echo "== fs helpers =="

h=$(mkhome)
for fn in mkd fp cwd; do
  assert_eq "$fn is a function" "function" "$(in_shell "$h" "printf %s \"\$(type -t $fn)\"")"
done

# mkd creates nested dirs and lands in them.
t=$(mktemp -d)
assert_eq "mkd creates and enters" "$t/a/b/c" \
  "$(in_shell "$h" "cd '$t' && mkd a/b/c && printf %s \"\$PWD\"")"
rm -rf "$t"

# fp filters $PATH case-insensitively, one entry per line.
# Append rather than replace: fp calls grep, which needs a working PATH.
assert_eq "fp filters PATH" "/ZZfp/lib" \
  "$(in_shell "$h" 'PATH="$PATH:/ZZfp/lib"; fp zzfp')"

rm -rf "$h"

echo
echo "== posh-git prompt =="

# Builds a repo with an upstream, runs git-prompt.sh in it, strips colour.
poshprompt() { ( cd "$1" && "$REPO/git-prompt.sh" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' ); }

newrepo() { # -> path to a clone with 'origin' upstream, one commit
  local base; base=$(mktemp -d)
  (
    cd "$base" && mkdir up && cd up
    git init -q -b main .
    git config user.email t@t; git config user.name t
    echo a > f.txt; echo b > g.txt; git add .; git commit -qm init
    cd "$base" && git clone -q up work
    cd work && git config user.email t@t; git config user.name t
  ) >/dev/null 2>&1
  printf '%s' "$base/work"
}

if command -v git >/dev/null; then
  assert_eq "not a repo" "" "$(poshprompt /tmp)"

  w=$(newrepo)
  assert_eq "clean and in sync"  "≡ +0 ~0 -0" "$(poshprompt "$w")"

  echo x >> "$w/f.txt"; echo x >> "$w/g.txt"
  assert_eq "two modified"       "≡ +0 ~2 -0" "$(poshprompt "$w")"

  rm "$w/g.txt"
  assert_eq "one modified one deleted" "≡ +0 ~1 -1" "$(poshprompt "$w")"

  ( cd "$w" && git checkout -q -- . ) >/dev/null 2>&1
  echo n > "$w/new.txt"
  assert_eq "untracked counts as add" "≡ +1 ~0 -0" "$(poshprompt "$w")"

  ( cd "$w" && git add new.txt ) >/dev/null 2>&1
  assert_eq "staged splits sections" "≡ +1 ~0 -0 | +0 ~0 -0" "$(poshprompt "$w")"

  ( cd "$w" && git commit -qm local ) >/dev/null 2>&1
  assert_eq "ahead" "↑1 +0 ~0 -0" "$(poshprompt "$w")"

  ( cd "$w" && git branch -q --unset-upstream ) >/dev/null 2>&1
  assert_eq "no upstream" "+0 ~0 -0" "$(poshprompt "$w")"

  rm -rf "$(dirname "$w")"

  # End-to-end through starship: the script passing on its own says nothing
  # about the module being wired into the prompt correctly.
  if command -v starship >/dev/null; then
    w=$(newrepo)
    echo x >> "$w/f.txt"
    out=$(cd "$w" && STARSHIP_CONFIG="$REPO/starship.toml" \
          starship module custom.git_posh 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')
    assert_contains "starship renders git_posh" "+0 ~1 -0" "$out"
    rm -rf "$(dirname "$w")"
  else
    skip "starship renders git_posh" "starship missing"
  fi
else
  skip "posh-git prompt" "git missing"
fi

echo
printf 'pass %d  fail %d  skip %d\n' "$pass" "$fail" "$skipped"
[ "$fail" -eq 0 ]
