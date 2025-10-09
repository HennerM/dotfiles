CONFIG_DIR=$(dirname $(realpath ${(%):-%x}))
DOT_DIR=$CONFIG_DIR/../

ZSH_DISABLE_COMPFIX=true
ZSH=$HOME/.oh-my-zsh
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
autoload -U compinit && compinit
zstyle ':completion:*' matcher-list 'l:|=*'
plugins=(zsh-autosuggestions
	zsh-syntax-highlighting
	zsh-completions
	zsh-history-substring-search
	z
	brew
	git
	you-should-use
	zsh-navigation-tools)

source $ZSH/oh-my-zsh.sh
source $CONFIG_DIR/aliases.sh
source $CONFIG_DIR/extras.sh
source $CONFIG_DIR/slurm.sh
which starship >/dev/null 2>&1 && eval "$(starship init zsh)"
