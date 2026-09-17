# scm_breeze's own installer appends its source line to ~/.bashrc, which here is
# a symlink into this repo. Clone it by hand instead - see README.
# Config lives in ~/.scmbrc and ~/.git.scmbrc, both linked by install.sh.
# Must stay ahead of 30-completion.sh: scm_breeze ships an older
# _get_comp_words_by_ref that bash-completion has to overwrite, not the reverse.
[ -s "$HOME/.scm_breeze/scm_breeze.sh" ] && . "$HOME/.scm_breeze/scm_breeze.sh"

# The repo index is gated on the assets-management flag .scmbrc clears, but its
# `c` alias and completion are registered unconditionally, leaving `c` pointing
# at a git_index function that never loads.
unalias c 2>/dev/null
complete -r c 2>/dev/null
