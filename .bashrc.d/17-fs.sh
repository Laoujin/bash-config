mkd() { mkdir -p "$1" && cd "$1"; }

fp() { printf '%s\n' "${PATH//:/$'\n'}" | grep -i -- "$1"; }

cwd() {
  if   command -v wl-copy  >/dev/null; then printf '%s' "$PWD" | wl-copy
  elif command -v xclip    >/dev/null; then printf '%s' "$PWD" | xclip -selection clipboard
  elif command -v clip.exe >/dev/null; then printf '%s' "$PWD" | clip.exe
  else echo "cwd: no clipboard tool" >&2; return 1
  fi
}
