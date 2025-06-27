CONFIG_DIR=$(dirname $(realpath ${(%):-%x}))
DOT_DIR=$CONFIG_DIR/../

ZSH_DISABLE_COMPFIX=true
ZSH=$HOME/.oh-my-zsh

plugins=(zsh-autosuggestions
	zsh-syntax-highlighting
	zsh-completions
	zsh-history-substring-search
	z
	brew
	git
	zsh-navigation-tools)

source $ZSH/oh-my-zsh.sh
source $CONFIG_DIR/aliases.sh
source $CONFIG_DIR/extras.sh

eval "$(starship init zsh)"
