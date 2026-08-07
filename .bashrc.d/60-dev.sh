export BUN_INSTALL="$HOME/.bun"
[ -d "$BUN_INSTALL/bin" ] && prepend_path "$BUN_INSTALL/bin"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

export NUGET_PACKAGES="$HOME/.nuget/packages"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
