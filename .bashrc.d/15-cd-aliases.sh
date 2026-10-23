alias code='cd "$HOME/code"'
alias projects='cd "$HOME/code/projects"'
alias itenium='cd "$HOME/code/itenium"'
alias ideas='cd "$HOME/code/_todo-projects"'
alias goca='cd "$HOME/code/projects/goca/mongo-replication"'
alias home='cd "$HOME/code/_personal/Home"'
alias pirateflix='cd "$HOME/code/_personal/sangu-be/htpc-site"'
alias courses='cd "$HOME/code/courses"'
alias scout='cd "$HOME/code/projects/Scout+Atlas/scout"'
alias atlas='cd "$HOME/code/projects/Scout+Atlas/atlas"'
alias adw='cd "$HOME/projects/ADW"'
alias adw2='cd "$HOME/code/itenium-projects/ADW/ADW"'
alias anvil='cd "$HOME/projects/BackOffice"'
alias portal='cd "$HOME/projects/Portal"'
alias template='cd "$HOME/projects/Itenium.Template"'
alias ui='cd "$HOME/projects/itenium-ui"'
alias yoink='cd "$HOME/projects/Yoink"'
alias hens='cd "$HOME/code/itenium-projects/Hens"'
alias security='cd "$HOME/code/security-bootcamp/bootcamp-security"'

alias bliki='cd "$HOME/code/bliki/blog-posts-new"'
alias userscripts='cd "$HOME/code/_personal/windows/UserScriptCollection"'
alias sangu='cd "$HOME/code/_personal/sangu-be"'
alias obsidian='cd "$HOME/code/_personal/Obsidian"'

alias confac='cd "$HOME/code/projects/confac/confac"'
alias eli='cd "$HOME/code/projects/stockoma/stockoma"'
alias forge='cd "$HOME/projects/Itenium.Forge.Core"'
alias forge2='cd "$HOME/code/projects/Itenium.Forge"'
alias ttc='cd "$HOME/code/projects/ttc/ttc-aalst"'

# Windows-side; needs a new path once this repo lives on Linux.
alias perch='cd /mnt/c/tools/Perch/perch-config'

# The `code` alias above shadows the VS Code CLI. `command` bypasses aliases.
cde() { command code "${@:-.}"; }
