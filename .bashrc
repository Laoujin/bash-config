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
