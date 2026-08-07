# Not unset after use: 50-host-* and 60-dev.sh reuse it.
prepend_path() {
  case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH";; esac
}

prepend_path "$HOME/.local/bin"
