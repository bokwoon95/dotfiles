path-prepend() { [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]] && PATH="$1${PATH:+":$PATH"}" }
path-append() { [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]] && PATH="${PATH:+"$PATH:"}$1" }
command -v tput &>/dev/null && ( tput setaf || tput AF ) &>/dev/null && COLORS_SUPPORTED=true
shopt -s checkwinsize # update the value of LINES and COLUMNS after each command
shopt -s globstar # enable recursive **
export LESS='-RiMSFX#4'
path-append "$HOME/local/bin"

# History
shopt -s histappend # append to history file, not overwrite
shopt -s cmdhist # save multiline commands
shopt -s lithist # delimit multiline commands in history with embedded newlines instead of semicolons if possible
HISTSIZE=
HISTFILESIZE=
HISTTIMEFORMAT="[%F %T] "
HISTIGNORE='ls:bg:fg:history'
HISTIGNORE="&:ls:ll:la:[bf]g:cd:vim:exit:pwd:clear:mount:umount:[ \t]*:?:??:!(+(*\ *))"
HISTCONTROL=ignorespace:ignoredups:erasedups
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

# Completion
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Editor
if command -v vim &>/dev/null; then
	export EDITOR=vim
fi

# PS1
if [ "$COLORS_SUPPORTED" ]; then
	if command -v __git_ps1 &>/dev/null && [ -f "$HOME/dotfiles/git-prompt.sh" ]; then
		. "$HOME/dotfiles/git-prompt.sh"
	fi
	if command -v __git_ps1 &>/dev/null; then
		PS1='\[$(tput bold)\]\H\[$(tput sgr0)\] \w $(__git_ps1 "(%s)")\n\u\[$(tput bold)\]\$\[$(tput sgr0)\] '
	else
		PS1='\[$(tput bold)\]\H\[$(tput sgr0)\] \w\n\u\[$(tput bold)\]\$\[$(tput sgr0)\] '
	fi
else
	PS1='\H \w\n\u\$ '
fi

# Aliases
alias cdz="$EDITOR $HOME/.bashrc"
alias sdz=". $HOME/.bashrc"
alias ..='cd .. && pwd && ls'
alias ...='cd ../.. && pwd && ls'
alias ....='cd ../../.. && pwd && ls'
alias ls='ls -F'
alias la='ls -AF'
alias ll='ls -AlF'
alias cp='cp -v'
alias mv='mv -v'
cdd() { if [ $# -eq 0 ]; then cd "$HOME" && pwd && ls; else cd "$1" && pwd && ls; fi }
mkcd() { mkdir -p "$1" && cd "$1"; }
alias sudo='sudo '

# GoLang
export GOROOT=/home/bokwoon/.go
export PATH=$GOROOT/bin:$PATH
export GOPATH=/home/bokwoon/go
export PATH=$GOPATH/bin:$PATH
alias g="git "

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
