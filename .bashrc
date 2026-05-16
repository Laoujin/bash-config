# Sourced by interactive bash shells. Bail on non-interactive.
case $- in *i*) ;; *) return;; esac

# Source ordered fragments. 50-host-* scripts self-detect their host.
if [ -d "$HOME/.bashrc.d" ]; then
  for f in "$HOME/.bashrc.d"/*.sh; do
    [ -r "$f" ] && . "$f"
  done
fi
