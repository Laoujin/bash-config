grep -qi microsoft /proc/version 2>/dev/null || return 0

export BROWSER=wslview

# V8 sizes each heap from total VM RAM, so concurrent node processes
# collectively overcommit the WSL memory cap and get OOM-killed.
export NODE_OPTIONS=--max-old-space-size=4096
