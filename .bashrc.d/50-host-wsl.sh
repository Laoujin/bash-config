grep -qi microsoft /proc/version 2>/dev/null || return 0

prepend_path() {
  case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH";; esac
}

prepend_path "$HOME/.local/bin"

export BUN_INSTALL="$HOME/.bun"
prepend_path "$BUN_INSTALL/bin"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

export BROWSER=wslview

unset -f prepend_path
