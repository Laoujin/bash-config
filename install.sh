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
link .inputrc      "$HOME/.inputrc"
link .bashrc.d     "$HOME/.bashrc.d"
link starship.toml "$HOME/.config/starship.toml"
link git-prompt.sh "$HOME/.config/starship-git-prompt.sh"
link .scmbrc       "$HOME/.scmbrc"
link .git.scmbrc   "$HOME/.git.scmbrc"

command -v starship >/dev/null || echo "warn  starship not installed - see README"
[ -d "$HOME/.scm_breeze" ]   || echo "warn  scm_breeze not cloned - see README"
