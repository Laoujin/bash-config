[ -f /etc/synoinfo.conf ] || return 0

prepend_path() {
  case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH";; esac
}

# Entware (opkg) — optional; safe if absent.
[ -d /opt/bin ]  && prepend_path /opt/bin
[ -d /opt/sbin ] && prepend_path /opt/sbin

# DSM sometimes leaves TERM empty over SSH, breaking readline/colors.
[ -z "$TERM" ] && export TERM=xterm-256color

unset -f prepend_path
