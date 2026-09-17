# PSReadLine's Alt+W: bank the line in history without running it. Lives here
# and not in .inputrc because only a shell function can reach the history list.
__push_line() {
  [ -n "$READLINE_LINE" ] && history -s "$READLINE_LINE"
  READLINE_LINE=
  READLINE_POINT=0
}
case $- in *i*) bind -x '"\ew": __push_line';; esac
