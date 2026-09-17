Porting Git-NumberedAdd
=======================

The PowerShell module [Git-NumberedAdd](https://github.com/itenium-be/Git-NumberedAdd)
gives numbered `git status` output and lets you act on files by index (`gs`, then
`ga 1 3-5`). This note records what exists in the Linux world, where those tools
differ, and what a port would have to reproduce.

Status: **trialling scm_breeze** since 2026-09-17. Installed via
`.bashrc.d/18-scm-breeze.sh`; config in `.scmbrc` and `.git.scmbrc`. Port not
written. Decide after a week of use.

Existing tools
--------------

| Tool             | Interface                                   | Numbering         | Maintained (Aug 2026)         |
|------------------|---------------------------------------------|-------------------|-------------------------------|
| [scm_breeze][sb] | `gs`, `ga 1 3-5` natively                   | one list, 1-based | 2913 stars, pushed 2026-07-23 |
| [git-number][gn] | `git number`, plus your own shell aliases   | one list, 1-based | 290 stars, pushed 2026-04-07  |
| [lazygit][lg]    | full-screen TUI, no numbering               | n/a               | 81110 stars, pushed daily     |
| [forgit][fg]     | fzf-driven interactive picker, no numbering | n/a               | 5054 stars, pushed 2026-08-01 |

[sb]: https://github.com/scmbreeze/scm_breeze
[gn]: https://github.com/holygeek/git-number
[lg]: https://github.com/jesseduffield/lazygit
[fg]: https://github.com/wfxr/forgit

The canonical scm_breeze repo is `scmbreeze/scm_breeze`. `ndbroadbent/scm_breeze`
is the original author's fork and is stale — it reports 0 stars.

Only `tig` is in apt. Everything above installs from source or a release binary.

Where they fall short
---------------------

Three Git-NumberedAdd behaviours that neither scm_breeze nor git-number has:

| Behaviour          | Git-NumberedAdd                                         | Both alternatives       |
|--------------------|---------------------------------------------------------|-------------------------|
| List model         | two lists, staged and working dir, each restarting at 0 | one combined list       |
| First index        | `0`                                                     | `1`                     |
| Digit-splitting    | `ga 123` means files 1, 2 and 3                         | `ga 123` means file 123 |
| All before / after | `-3` and `+3`                                           | not supported           |

Ranges (`ga 1 3-5`) work in all three.

The digit-splitting rule is the one most likely to be missed in daily use, since
it is what makes `ga 012` faster than `ga 0 1 2`.

scm_breeze
----------

Closest match to the existing muscle memory, and the only option where `gs` and
`ga N` work with no extra aliasing.

It also exports one variable per changed file — `$e1`, `$e2`, … — usable with any
command, not just git:

```bash
vim $e3
rm $e2
```

That is strictly more capable than Git-NumberedAdd's `gn` utility.

The cost is that it is a framework, not a plugin. It installs a repository index
with tab completion, `ls` shortcuts, keyboard bindings and a large alias set.

The feared alias collision turned out to be small. Measured against all fragments:
354 names defined, three of them ours.

| Name   | scm_breeze wants       | Resolution                                 |
|--------|------------------------|--------------------------------------------|
| `gt`   | `git tag`              | `git_tag_alias="gtag"` in `.git.scmbrc`    |
| `code` | wrapped VS Code binary | dropped from `scmb_wrapped_shell_commands` |
| `ls`   | wrapped `/usr/bin/ls`  | dropped from `scmb_wrapped_shell_commands` |

`ll` and `la` are taken over on purpose — scm_breeze numbers them and exports an
`$e<n>` per entry, which is the point.

Two things bite that the README does not mention:

- With assets management off, `c` is still aliased to a `git_index` function that
  never loads. `18-scm-breeze.sh` unaliases it.
- Without ruby, `gs` uses a shell fallback whose cost grows with the number of
  changed files — on `/mnt/c` with 8 changes, 2423ms against 998ms with ruby and
  498ms for plain `git status`. `ll` also loses its numbering entirely.

See the README for the install; its own `install.sh` must not be run, because it
appends a source line to `~/.bashrc`, which is a symlink into this repo.

git-number
----------

The opposite trade: a single Go binary, no shell footprint, no collisions. The
interface is `git number <subcommand>`, so the short names come from aliases you
write:

```bash
alias g='git number --column'
alias ga='git number add'
alias gd='git number diff'
```

Not in apt. Build from source or take a release binary.

Porting instead
---------------

A faithful port is roughly 150 lines of bash plus tests, and would live in
`.bashrc.d/19-git-numbered.sh`. State survives between `gs` and `ga` in plain
shell arrays, because functions run in the current shell.

### Index syntax to reproduce

| Argument             | Meaning                                                     |
|----------------------|-------------------------------------------------------------|
| `3`                  | index 3                                                     |
| `3-5`                | 3, 4, 5                                                     |
| `-3`                 | everything before 3, so 0, 1, 2                             |
| `+3`                 | everything after 3, so 4, 5, … to the end                   |
| `035`                | split into 0, 3, 5                                          |
| trailing non-numeric | treated as a commit message: `git add` then `git commit -m` |

A multi-digit token splits into digits when any of these hold: it has a leading
zero, or the list has fewer than 11 entries, or the value is out of bounds as a
single index. Otherwise it is one index.

### Commands

| Alias     | Does                                  | Reads from   |
|-----------|---------------------------------------|--------------|
| `gs`      | numbered status, both lists           | —            |
| `ga`      | `git add`                             | working dir  |
| `gap`     | `git add --patch`                     | working dir  |
| `gd`      | `git diff`                            | working dir  |
| `gdc`     | `git diff --cached`                   | staging area |
| `grs`     | `git reset HEAD`                      | staging area |
| `gco`     | `git checkout`                        | working dir  |
| `gn`      | print the filename at an index        | working dir  |
| `gsl`     | cd to that file's directory           | working dir  |
| `gas`     | `git update-index --assume-unchanged` | working dir  |
| `gasl`    | list assumed-unchanged files          | —            |
| `gnoas`   | `--no-assume-unchanged`               | working dir  |
| `ghide`   | `git update-index --skip-worktree`    | working dir  |
| `glh`     | list skip-worktree files              | —            |
| `gunhide` | `--no-skip-worktree`                  | working dir  |

### Name collisions

`gs` shadows `/usr/bin/gs` (Ghostscript). `command gs` still reaches it. The other
fourteen names are unused on this machine.

### Open question

Whether `gs` should show per-file line counts (`+12 -3`). The PowerShell module
has `includeNumstat = $true`, so that is the current behaviour, but it costs an
extra `git diff --numstat` call per invocation. That is cheap on ext4 and not on
`/mnt/c`, where `git status` alone already costs ~600ms in a real repo.

Recommendation
--------------

Installed. Use it for a week before writing any code. The only real question left
is whether the 1-based single-list model and the loss of digit-splitting fight the
fingers. If they do, port Git-NumberedAdd and keep the exact semantics above.

`rm -rf ~/.scm_breeze` uninstalls: the fragment goes quiet on its own.
