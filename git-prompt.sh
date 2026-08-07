#!/usr/bin/env bash
# posh-git style git segment for the starship prompt: "[main ≡ +0 ~2 -0 | +0 ~1 -0]"
# Index section (green) is printed only when the index is dirty, matching posh-git.
# Emits its own ANSI colour, so the starship custom module must not set a style.
#
# The branch is rendered here rather than by starship's git_branch so one module
# owns both brackets: a half-failed render can't leave a dangling "[".
#
# One `git status -b` call, not status + rev-parse + rev-list: on /mnt/c every
# git invocation costs 50-190ms, so the extra round trips were most of the prompt.
set -u

status=$(git --no-optional-locks status --porcelain=v1 -unormal -b \
           --ignore-submodules=all 2>/dev/null) || exit 0

GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; RESET=$'\033[0m'
BRANCH=$'\033[1;35m'

ia=0 im=0 id=0   # index: added, modified, deleted
wa=0 wm=0 wd=0   # worktree: added (untracked), modified, deleted
conflicts=0
upstream=""
branch=""

while IFS= read -r line; do
  [ -z "$line" ] && continue

  # Branch header, always first: "## main...origin/main [ahead 1, behind 2]"
  if [ "${line:0:3}" = "## " ]; then
    head=${line#\#\# }
    if [ "$head" = "HEAD (no branch)" ]; then
      branch="($(git rev-parse --short HEAD 2>/dev/null))"
    else
      branch=${head%%...*}
      branch=${branch%% *}
    fi
    case "$line" in
      *...*)
        ahead=0 behind=0
        case "$line" in *"ahead "*) t=${line##*ahead }; ahead=${t%%[!0-9]*};; esac
        case "$line" in *"behind "*) t=${line##*behind }; behind=${t%%[!0-9]*};; esac
        if   [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then upstream="↑${ahead}↓${behind} "
        elif [ "$ahead" -gt 0 ];                        then upstream="↑${ahead} "
        elif [ "$behind" -gt 0 ];                       then upstream="↓${behind} "
        else                                                 upstream="≡ "
        fi
        ;;
    esac
    continue
  fi

  x=${line:0:1}; y=${line:1:1}

  if [ "$x$y" = "??" ]; then wa=$((wa + 1)); continue; fi
  # Any U, or AA/DD, is an unmerged path.
  case "$x$y" in U?|?U|AA|DD) conflicts=$((conflicts + 1)); continue;; esac

  case "$x" in A) ia=$((ia + 1));; M|R|C) im=$((im + 1));; D) id=$((id + 1));; esac
  case "$y" in M) wm=$((wm + 1));; D) wd=$((wd + 1));; esac
done <<< "$status"

out="[${BRANCH}${branch}${RESET} ${upstream}"
[ $((ia + im + id)) -gt 0 ] && out="$out${GREEN}+${ia} ~${im} -${id}${RESET} | "
out="$out${YELLOW}+${wa} ~${wm} -${wd}${RESET}"
[ "$conflicts" -gt 0 ] && out="$out ${RED}!${conflicts}${RESET}"

printf '%s]' "$out"
