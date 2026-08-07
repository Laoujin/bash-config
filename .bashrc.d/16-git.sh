alias gt=git
alias gut=git
alias gti=git
alias got=git
alias guit=git
alias giut=git
alias giot=git
alias goit=git
alias igt=git

pr() { git push -u origin HEAD && gh pr create --web --base "${1:-main}"; }
