Candidate shell options
=======================

Not installed. Shortlist of `shopt`/history/readline settings still on the table,
kept so the decision doesn't have to be made twice.

Already in `.bashrc.d/14-cd.sh`: `cdspell`, `dirspell`, `autocd`, `nocaseglob`.
Already in `.inputrc`: case-insensitive completion, one-TAB listing, prefix history on ↑/↓.

Worth adding
------------

| Setting                                           | Effect                                                                                                        |
|---------------------------------------------------|---------------------------------------------------------------------------------------------------------------|
| `shopt -s globstar`                               | `**/*.ts` recurses.                                                                                            |
| `shopt -s direxpand`                              | TAB expands `$VAR/`, `~/` into the real path on the line.                                                       |
| `shopt -s no_empty_cmd_completion`                | Empty line + TAB stops offering every command on `$PATH`.                                                       |
| `shopt -s checkjobs`                              | Refuses the first `exit` while jobs are still running.                                                          |
| `shopt -s histverify`                             | `!!`/`!$` land on the line for review instead of running immediately.                                           |
| `HISTTIMEFORMAT='%F %T '`                         | Timestamps in `history`. Written to the file from then on, not retroactive.                                     |
| `HISTIGNORE='ls:ll:la:cd:pwd:exit:clear:history'` | Keeps the noise out of the file.                                                                                |
| `PROMPT_COMMAND='history -a'`                     | Each command hits `~/.bash_history` at once, so parallel terminals don't clobber each other's history on exit.  |

Readline, PSReadLine parity
---------------------------

For `.inputrc`.

| Setting                                                | Effect                                                                                        |
|--------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| `"\e[1;5C": forward-word` / `"\e[1;5D": backward-word` | Ctrl+←/→ word jumps.                                                                           |
| `"\C-H": backward-kill-word` / `"\e[3;5~": kill-word`  | Ctrl+Backspace / Ctrl+Del delete a word. Windows Terminal sends `^H` for the former.            |
| `set mark-symlinked-directories on`                    | Completion appends `/` to symlinked dirs too.                                                   |
| `set skip-completed-text on`                           | No duplicated tail when completing mid-word.                                                    |
| `set bell-style none`                                  | Kills the terminal beep.                                                                        |

Choice, not both
----------------

TAB either lists matches (current behaviour) or cycles through them like PSReadLine:

```
TAB: menu-complete
"\e[Z": menu-complete-backward
set menu-complete-display-prefix on
```

Cycling means the full list is no longer visible at a glance.

Rejected
--------

| Setting                     | Why not                                                        |
|-----------------------------|------------------------------------------------------------------|
| `shopt -s nullglob`         | Changes glob semantics under scripts; unmatched globs vanish.     |
| `shopt -s dotglob`          | Same, and `*` starts matching dotfiles.                           |
| `set -o noclobber`          | `>` starts erroring on an existing file, needs `>|`.              |
| `shopt -s extglob`          | `bash-completion` already turns it on.                            |
| `CDPATH`                    | `15-cd-aliases.sh` covers the same dirs; `cd` starts echoing the resolved path and scripts can `cd` into the wrong dir. |

Bigger than any flag
--------------------

[fzf](https://github.com/junegunn/fzf): fuzzy Ctrl+R over history, Ctrl+T file insertion.
A package plus `eval "$(fzf --bash)"` in a fragment.
