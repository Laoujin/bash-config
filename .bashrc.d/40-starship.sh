# Keep the shell usable if starship isn't installed yet.
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
