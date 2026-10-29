scm_breeze Cheat Sheet
======================

Numbered `git status` and file-by-index commands. Installed by
`.bashrc.d/18-scm-breeze.sh`; see the README for setup, and
`PORTING_GIT_NUMBEREDADD.md` for why this over a port of Git-NumberedAdd.

`gs` numbers every changed file and exports `$e1`…`$eN`. `git` itself is a shell
function that expands numeric arguments, so every `git x` alias below takes
indices — not just `ga`.

```bash
gs              # 1 README.md   2 install.sh   3 tests/test-fragments.sh
ga 1 3          # stage 1 and 3
gd 2            # diff 2
ga 2-5          # ranges work
vim $e3         # the variables work bare, with any command
ge tar czf b.tgz 1 2   # ge expands indices for anything not pre-wrapped
```

`git_aliases` prints the live list at any time.

Status and staging
------------------

| Alias          | Runs                                    | Index |
|----------------|-----------------------------------------|-------|
| `gs`           | numbered `git status`, sets `$e1`…`$eN` | —     |
| `ga`           | `git add`                               | yes   |
| `gaa`          | `git add --all .`                       | —     |
| `gau`          | `git add -u`                            | —     |
| `gap`          | `git add -p`                            | yes   |
| `grs`          | `git reset`                             | yes   |
| `grsh`         | `git reset --hard`                      | yes   |
| `grm`          | `git rm`                                | yes   |
| `grt`          | `git restore`                           | yes   |
| `gco`          | `git checkout`                          | yes   |
| `gce` / `gcef` | `git clean` / `-fd`                     | —     |
| `gst` / `gss`  | plain `git status` / `-s`               | —     |
| `gsf`          | list files a commit touched             | —     |

Diff
----

| Alias  | Runs                   | Index |
|--------|------------------------|-------|
| `gd`   | `git diff`             | yes   |
| `gdc`  | `git diff --cached`    | yes   |
| `gdw`  | `git diff --word-diff` | yes   |
| `gdnw` | `git diff -w`          | yes   |
| `gdt`  | `git difftool`         | yes   |
| `gmt`  | `git mergetool`        | yes   |
| `gbl`  | `git blame`            | yes   |

Commit
------

| Alias          | Runs                                     |
|----------------|------------------------------------------|
| `gc` / `gcv`   | `git commit` / `--verbose`               |
| `gca`          | add all, then commit                     |
| `gch`          | `git commit -C HEAD`                     |
| `gcm` / `gcmh` | `git commit --amend` / `--amend -C HEAD` |
| `gcp`          | `git cherry-pick`                        |

Branch, merge, rebase
---------------------

| Alias                            | Runs                                     | Index |
|----------------------------------|------------------------------------------|-------|
| `gb`                             | numbered branch list                     | —     |
| `gba` / `gbd` / `gbD` / `gbm`    | branch `-a` / `-d` / `-D` / `-m`         | yes   |
| `gcb`                            | `git checkout -b`                        | —     |
| `gsw`                            | `git switch`                             | yes   |
| `gm` / `gmff` / `gmnff`          | `git merge` / `--ff` / `--no-ff`         | yes   |
| `grb` / `grbi` / `grbc` / `grba` | rebase / `-i` / `--continue` / `--abort` | yes   |
| `grsl`                           | undo last commit, keep changes           | —     |

Remote and sync
---------------

| Alias          | Runs                    |
|----------------|-------------------------|
| `gf` / `gfa`   | `git fetch` / `--all`   |
| `gfr`          | fetch then rebase       |
| `gpl` / `gplr` | `git pull` / `--rebase` |
| `gps` / `gpsf` | `git push` / `-f`       |
| `gpls`         | pull then push          |
| `gr`           | `git remote -v`         |
| `gcl`          | `git clone`             |
| `gpr`          | `gh pr`                 |

Log, show, stash, misc
----------------------

| Alias                                | Runs                               |
|--------------------------------------|------------------------------------|
| `gl` / `gla`                         | graph log / including all branches |
| `glg` / `glst`                       | graph, last 5 / with `--stat`      |
| `gsh` / `gsm`                        | `git show` / `--summary`           |
| `gwc`                                | `git whatchanged`                  |
| `gash` / `gasha` / `gashp` / `gashl` | stash / apply / pop / list         |
| `gtrep`                              | numbered `git grep`                |
| `gtop`                               | print repo root                    |
| `gtag`                               | `git tag`                          |
| `gsu` / `gsur`                       | submodule update / recursive       |
| `gwt` / `gwta` / `gwtr`              | worktree / add / remove            |
| `git_aliases`                        | print the live alias list          |

Functions with no alias
-----------------------

| Function                 | Does                                       |
|--------------------------|--------------------------------------------|
| `git_ignore`             | append a pattern to `.gitignore`           |
| `git_exclude`            | same, but `.git/info/exclude` (local only) |
| `git_exclude_basename`   | exclude by filename anywhere in the tree   |
| `git_bisect_grep`        | bisect for the commit introducing a string |
| `git_branch_delete_all`  | delete every branch matching a pattern     |
| `git_swap_remotes`       | swap two remotes                           |
| `git_set_default_remote` | set the push remote for the branch         |
| `git_submodule_rm`       | remove a submodule properly                |
| `git_remove_history`     | purge a file from all history              |
| `git_clear_vars`         | unset the `$e<n>` variables                |
| `update_scm_breeze`      | git pull in `~/.scm_breeze`                |

Keybindings
-----------

| Keys             | Does                                  |
|------------------|---------------------------------------|
| `Ctrl+x` `Space` | commit all, prompts for the message   |
| `Ctrl+x` `c`     | add by index, then commit             |
| `Ctrl+x` `v`     | commit all, append `[ci skip]`        |
| `Ctrl+x` `z`     | add all, amend HEAD, keep the message |

Beyond git
----------

`cat`, `cp`, `mv`, `rm`, `ln`, `cd`, `less`, `vim`, `emacs`, `gedit` and `subl`
are pre-wrapped, so `rm 2 4` works. `ls` and `code` are deliberately left out —
see `.git.scmbrc`. For anything else, prefix with `ge`.

`ll` and `la` are numbered listings, not `ls -alF`. They set `$e<n>` for every
entry in the directory, the same way `gs` does for changed files.

Pitfalls
--------

**`gs`, `gb` and `ll` share one index namespace.** Whichever ran last wins. After
`gb`, `gco 1` switches to branch 1, not file 1 — silently, with no error. A bare
`ll` is enough to repoint `$e1` at a directory entry.

**`gs` shadows Ghostscript.** `command gs` still reaches `/usr/bin/gs`.

**Indices are 1-based and one flat list**, unlike Git-NumberedAdd's 0-based pair
of lists. `ga 123` is file 123, not files 1, 2 and 3.

**Stale indices.** The numbers are whatever the last `gs` printed. After an
external change — a rebase, another terminal, an IDE staging something — rerun
`gs` before acting by number.

**Ruby is required in practice.** Without it `gs` falls back to a shell
implementation that slows down as the diff grows, and `ll` loses its numbering.

**Don't run `~/.scm_breeze/install.sh`.** It appends a source line to `~/.bashrc`,
which is a symlink into this repo.

Uninstall
---------

```bash
rm -rf ~/.scm_breeze
```

The fragment goes quiet on its own; the two rc symlinks become inert.
