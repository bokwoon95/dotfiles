uname | grep -q Darwin && export macos=true
uname | grep -q MINGW && ! command -v pacman &>/dev/null export gitbash=true
uname | grep -q Linux  && command -v clip.exe &>/dev/null && export wsl=true
uname | grep -q Linux  && ! command -v clip.exe &>/dev/null && export linux=true
path-prepend() { [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]] && PATH="$1${PATH:+":$PATH"}"; }
path-append() { [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]] && PATH="${PATH:+"$PATH:"}$1"; }
command -v tput &>/dev/null && ( tput setaf || tput AF ) &>/dev/null && COLORS_SUPPORTED=true
stty -ixon
path-append "$HOME/local/bin"

export LESS='-RiMSFX#4'

if echo $0 | grep -q bash; then
  shopt -s checkwinsize # update the value of LINES and COLUMNS after each command
  shopt -s globstar # enable recursive **
elif echo $0 | grep -q zsh; then
  setopt NO_BEEP # don't beep on error
  setopt INTERACTIVE_COMMENTS # Allow comments even in interactive shells (especially for Muness)
  setopt AUTO_CD # If you type foo, and it isn't a command, and it is a directory in your cdpath, go there
  setopt CDABLEVARS # if argument to cd is the name of a parameter whose value is a valid directory, it will become the current directory
  setopt PUSHD_IGNORE_DUPS # don't push multiple copies of the same directory onto the directory stack
  setopt EXTENDED_GLOB # treat #, ~, and ^ as part of patterns for filename generation
  setopt MULTIOS # perform implicit tees or cats when multiple redirections are attempted
  # setopt CORRECT # spelling correction for commands
  # setopt CORRECTALL # spelling correction for arguments
fi

# History
if echo $0 | grep -q bash; then
  shopt -s histappend # append to history file, not overwrite
  shopt -s cmdhist # save multiline commands
  shopt -s lithist # delimit multiline commands in history with embedded newlines instead of semicolons if possible
  HISTSIZE=
  HISTFILESIZE=
  HISTTIMEFORMAT="[%F %T] "
  HISTIGNORE="&:ls:ll:la:[bf]g:cd:vim:exit:pwd:clear:mount:umount:[ \t]*:?:??:!(+(*\ *))"
  HISTCONTROL=ignorespace:ignoredups:erasedups
  PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
elif echo $0 | grep -q zsh; then
  HISTFILE="$HOME/.zsh_history"
  SAVEHIST=10000                              # Big history
  HISTSIZE=10000                              # Big history
  setopt EXTENDED_HISTORY                     # Include more information about when the command was executed, etc
  setopt APPEND_HISTORY                       # Allow multiple terminal sessions to all append to one zsh command history
  setopt HIST_FIND_NO_DUPS                    # When searching history don't display results already cycled through twice
  setopt HIST_EXPIRE_DUPS_FIRST               # When duplicates are entered, get rid of the duplicates first when we hit $HISTSIZE
  setopt HIST_IGNORE_SPACE                    # Don't enter commands into history if they start with a space
  setopt HIST_VERIFY                          # makes history substitution commands a bit nicer. I don't fully understand
  setopt SHARE_HISTORY                        # Shares history across multiple zsh sessions, in real time
  setopt HIST_IGNORE_DUPS                     # Do not write events to history that are duplicates of the immediately previous event
  setopt INC_APPEND_HISTORY                   # Add commands to history as they are typed, don't wait until shell exit
  setopt HIST_REDUCE_BLANKS                   # Remove extra blanks from each command line being added to history
fi

# Completion
if echo $0 | grep -q bash; then
  if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
      . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
      . /etc/bash_completion
    fi
  fi
elif echo $0 | grep -q zsh; then
  # setopt always_to_end # When completing from the middle of a word, move the cursor to the end of the word
  setopt AUTO_MENU # show completion menu on successive tab press. needs unsetop menu_complete to work
  setopt AUTO_NAME_DIRS # any parameter that is set to the absolute name of a directory immediately becomes a name for that directory
  setopt COMPLETE_IN_WORD # Allow completion from within a word/phrase
  unsetopt MENU_COMPLETE # do not autoselect the first completion entry
  # bindkey '^[[Z' reverse-menu-complete
  autoload -U compinit
  compinit
  zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
  zstyle ':completion:*' menu select
  zstyle -e ':completion:*:default' list-colors 'reply=("${PREFIX:+=(#bi)($PREFIX:t)(?)*==34=34}:${(s.:.)LS_COLORS}")';
  # zstyle ':completion:*:descriptions' format '%U%B%d%b%u'
  # zstyle ':completion:*:warnings' format '%BSorry, no matches for: %d%b'
  # setopt correctall
  setopt MENU_COMPLETE
  # zsh-autosuggestions settings
  [ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && . "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
  # add plugins=(zsh-autosuggestions) under plugins=(git) (L54)
  # ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=0'
  # ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=187' #white, incompatible with iceberg
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=106'
  #fg=187 for solarized dark
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
  ZSH_AUTOSUGGEST_USE_ASYNC=true
  # Remove forward-char widgets from ACCEPT
  ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=("${(@)ZSH_AUTOSUGGEST_ACCEPT_WIDGETS:#forward-word}")
  # Add forward-char widgets to PARTIAL_ACCEPT
  ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS+=(forward-word)
  bindkey '^ ' forward-word
fi

# Editor
if command -v nvim &>/dev/null; then
  alias vim="nvim"
  export EDITOR="nvim"
elif command -v vim &>/dev/null; then
  export EDITOR="vim"
fi
[ -f "$HOME/minvim/min.vim" ] && alias minvim="vim -u $HOME/minvim/min.vim"

# PS1
if echo $0 | grep -q bash; then
  if [ "$COLORS_SUPPORTED" ]; then
    if ! command -v __git_ps1 &>/dev/null && [ -f "$HOME/dotfiles/git-prompt.sh" ]; then
      . "$HOME/dotfiles/git-prompt.sh"
    fi
    if command -v __git_ps1 &>/dev/null; then
      PS1='\H \[`tput bold`\]\w\[`tput sgr0`\] `__git_ps1 "(%s)"`\n\u\[`tput bold`\]\$\[`tput sgr0`\] '
    else
      PS1='\H \[`tput bold`\]\w\[`tput sgr0`\]\n\u\[`tput bold`\]\$\[`tput sgr0`\] '
    fi
  else
    PS1='\H \w\n\u\$ '
  fi
  [ "$gitbash" ] && PS1='\[\033]0;$TITLEPREFIX:$PWD\007\]\n\[\033[32m\]\u@\h \[\033[35m\]$MSYSTEM \[\033[33m\]\w\[\033[36m\]`__git_ps1`\[\033[0m\]\n\$ '
elif echo $0 | grep -q zsh; then
  setopt PROMPT_SUBST # Enable parameter expansion, command substitution, and arithmetic expansion in the prompt
  setopt TRANSIENT_RPROMPT # only show the rprompt on the current prompt
  autoload -Uz vcs_info
  precmd () {
    vcs_info
  }
  setopt prompt_subst
  PS1="%M %B%~%b"
  PS1="$PS1\$vcs_info_msg_0_"
  # prompt-end
  PS1="$PS1"$'\n'"%n%B$%b "
fi

# FZF
if echo $0 | grep -q bash; then
  [ -f ~/.fzf.bash ] && source ~/.fzf.bash
elif echo $0 | grep -q zsh; then
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
fi
if command -v ag >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='ag --hidden -u --ignore .git -g ""'
elif command -v rg >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='rg --hidden -l ""'
else
  export FZF_DEFAULT_COMMAND='find .'
fi

# Keys
if echo $0 | grep -q zsh; then
  # To see the key combo you want to use just do:
  # cat > /dev/null
  # And press it
  bindkey -e
  bindkey "^K"      kill-line                            # ctrl-k
  bindkey "^U"      backward-kill-line                   # ctrl-u
  bindkey "^R"      history-incremental-search-backward  # ctrl-r
  bindkey "^A"      beginning-of-line                    # ctrl-a
  bindkey "^E"      end-of-line                          # ctrl-e
  bindkey "[B"      history-search-forward               # down arrow
  bindkey "[A"      history-search-backward              # up arrow
  bindkey "^D"      delete-char                          # ctrl-d
  bindkey "^F"      forward-char                         # ctrl-f
  bindkey "^B"      backward-char                        # ctrl-b
  fancy-ctrl-z () {
    if [[ $#BUFFER -eq 0 ]]; then
      BUFFER="fg"
      zle accept-line
    else
      zle push-input
      zle clear-screen
    fi
  }
  zle -N fancy-ctrl-z
  bindkey '^Z' fancy-ctrl-z
  # Enable Ctrl-x-e to edit command line
  autoload -U edit-command-line
  # Emacs style
  zle -N edit-command-line
  bindkey '^xe' edit-command-line
  bindkey '^x^e' edit-command-line
fi

# youtube-dl
if command -v youtube-dl &>/dev/null; then
  youtube-dl3() {
    local help='Provide Youtube URL(s) to extract their mp3. Playlist URLs will have all their audio files inside extracted. Make sure to surround the URL in quotes'
    [ $# -eq 0 ] && echo "$help" && return
    for url in "$@"; do 
      youtube-dl -x --audio-format mp3 "$url"
    done
  }
  youtube-dl4() {
    local help='Provide Youtube URL(s) to extract their mp4. Playlist URLs will have all their audio files inside extracted. Make sure to surround the URL in quotes'
    [ $# -eq 0 ] && echo "$help" && return
    for url in "$@"; do 
      youtube-dl -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio' --merge-output-format mp4 "$url"
    done
  }
fi

# ffmpeg
if command -v ffmpeg &>/dev/null; then
  fftrim() {
local help="HOW TO USE: fftrim takes in 3 arguments, input_file.mp3/.mp4, start_time, duration
EXAMPLE: fftrim song.mp3 0 1:00     (trims song.mp3 from 0:00 onward, output duration will be 1 minute long
EXAMPLE: fftrim video.mp4 0:30 1:00 (trims video.mp4 from 0:30 onward, output duration will be 1 minute long)"
    [ $# -eq 0 ] && echo "$help" && return
    [ $# -ne 3 ] && echo 'NOTE: fftrim takes in only 3 arguments! input_file.mp3/.mp4, start_time, duration' && return
    local fext="$(echo "$1" | awk -F. '{print $NF}')"; if [ "$fext" = "$1" -o ".$fext" = "$1" ]; then fext=''; else fext=".$fext"; fi
    local fname="$(basename "$1" "$fext")"
    case "$fext" in .mp3|.mp4);; *)echo 'file is not an mp3 or mp4!'; return;; esac
    ffmpeg -i "$1" -ss "$2" -t "$3" -acodec copy vsync 2 "$fname$fext"
  }
  ffadeout() {
local help="HOW TO USE: ffadeoutmp3 takes in 3 arguments, input_file.mp3, start_of_fade(only accepts minutes:seconds format), duration_of_fade(how long the fade should be stretched over, in seconds. 
Everything after the fade will be silenced)"
    [ $# -eq 0 ] && echo "$help" && return
    [ $# -ne 3 ] && echo 'ffadeoutmp3 takes in only 3 arguments! input_file.mp3, start_of_fade(minutes:seconds), duration_of_fade(seconds)' && return
    local fext="$(echo "$1" | awk -F. '{print $NF}')"; if [ "$fext" = "$1" -o ".$fext" = "$1" ]; then fext=''; else fext=".$fext"; fi
    local fname="$(basename "$1" "$fext")"
    case "$fext" in .mp3);; *)echo 'file is not an mp3!'; return;; esac
    local minutes="$(echo "$2" | awk -F: '{print $1}')"
    local seconds="$(echo "$2" | awk -F: '{print $2}')"
    local totalseconds=$(($minutes*60 + $seconds))
    ffmpeg -i "$1" -af "afade=t=out:st='$totalseconds':d='$3'" "$fname""F.mp3";
  }
  ff-convert-to-mp4() {
local help="HOW TO USE: ff-convert-to-mp4 accepts only TS/flv/mov/avi/mkv/wmv files.
EXAMPLE: ff-convert-to-mp4 video1.flv
EXAMPLE: ff-convert-to-mp4 *.flv
EXAMPLE: ff-convert-to-mp4 video1.TS video2.TS video3.mov"
    [ $# -eq 0 ] && echo "$help" && return
    for filename in "$@"; do
      local fext="$(echo "$filename" | awk -F. '{print $NF}')"; if [ "$fext" = "$filename" -o ".$fext" = "$filename" ]; then fext=''; else fext=".$fext"; fi
      local fname="$(basename "$filename" "$fext")"
      echo "$filename"
      case "$fext" in
        .mov|.MOV|.flv|.FLV|.mkv|.MKV) ffmpeg -i "$filename" -codec copy "$fname.mp4";;
        .ts|.TS) ffmpeg -i "$filename" -acodec copy -vcodec copy "$fname.mp4";;
        .avi|.AVI) ffmpeg -i "$filename" -c:a aac -b:a 128k -c:v libx264 -crf 23 "$fname.mp4";;
        .wmv|.WMV) ffmpeg -i "$filename" -c:v libx264 -crf 23 -c:a aac -strict -2 -q:a 100 "$fname.mp4";;
        .webm|.WEBM) ffmpeg -i "$filename" "$fname.mp4";;
        *) echo "unrecognized extension '$fext'";;
      esac
      echo "----------------------------------------"
    done
  }
  ff-convert-to-mp3() {
local help="HOW TO USE: ff-convert-to-mp3 accepts only flac files.
EXAMPLE: ff-convert-to-mp3 music1.flac
EXAMPLE: ff-convert-to-mp3 *.flac"
    [ $# -eq 0 ] && echo "$help" && return
    for filename in "$@"; do
      local fext="$(echo "$filename" | awk -F. '{print $NF}')"; if [ "$fext" = "$filename" -o ".$fext" = "$filename" ]; then fext=''; else fext=".$fext"; fi
      local fname="$(basename "$filename" "$fext")"
      echo "$filename"
      case "$fext" in
        .flac|.FLAC) ffmpeg -i "$filename" -ab 320k -map_metadata 0 -id3v2_version 3 "$fname.mp3";;
        *) echo "unrecognized extension '$fext'";;
      esac
      echo "----------------------------------------"
    done
  }
fi

# Aliases
echo $0 | grep -q zsh && rcfile="$HOME/.zshrc" || rcfile="$HOME/.bashrc"
alias cdz="$EDITOR $rcfile"
alias sdz=". $rcfile"
alias ..='cd .. && pwd && ls'
alias ...='cd ../.. && pwd && ls'
alias ....='cd ../../.. && pwd && ls'
alias ls='ls -F'
alias la='ls -AF'
alias ll='ls -AlF'
alias cp='cp -v'
alias mv='mv -v'
cdd() { if [ $# -eq 0 ]; then cd "$HOME" && pwd && ls; else cd "$1" && pwd && ls; fi; }
mkcd() { mkdir -p "$1" && cd "$1"; }
alias sudo='sudo '

# macOS
if [ "$macos" ]; then
  alias xo=open
  alias bx='brew upgrade && brew cleanup'
  alias screensaver=/System/Library/CoreServices/ScreenSaverEngine.app/Contents/MacOS/ScreenSaverEngine
  command -v rmtrash &>/dev/null && alias rmt=rmtrash
  # Directories
  alias dbox="cd $HOME/Dropbox/ && pwd && ls"
  alias doc="cd $HOME/Documents/ && pwd && ls"
  alias desk="cd $HOME/Desktop/ && pwd && ls"
  alias down="cd $HOME/Downloads/ && pwd && ls"
  alias vol="cd /Volumes/ && pwd && ls"
  alias trash="cd $HOME/.Trash/ && pwd && ls"
fi

# Windows
if [ "$wsl" ] || [ "$gitbash" ]; then
  xo() { cmd.exe /C start "$@"; }
  command -v recycle.exe &>/dev/null && alias rmt='recycle.exe'
fi

cdls() {
  local dest="$1"
  uname | grep -q MINGW && ! command -v pacman &>/dev/null && local gitbash=true
  uname | grep -q Linux && command -v clip.exe &>/dev/null && local wsl=true
  cd "$dest" && pwd && ls
}

# Git Bash
if [ "$gitbash" ]; then
  alias dbox="cd $HOME/Dropbox/ && pwd && ls"
  alias doc="cd $HOME/Documents/ && pwd && ls"
  alias desk="cd $HOME/Desktop/ && pwd && ls"
  alias down="cd /d/Users/$(whoami)/Downloads/ && pwd && ls"
fi

# WSL
if [ "$wsl" ]; then
  alias dbox="cd $HOME/Dropbox/ && pwd && ls"
  alias doc="cd $HOME/Documents/ && pwd && ls"
  alias desk="cd $HOME/Desktop/ && pwd && ls"
  alias down="cd /mnt/d/Users/$(whoami)/Downloads/ && pwd && ls"
fi

# Linux
if [ "$linux" ]; then
  alias xo='xdg-open'
fi

# Tmux
tax () {
  if [ $# -eq 0 ]; then
    if [ "$macos" ]; then
      if [ "$TERM_PROGRAM" == 'iTerm.app' ]; then
        TERM=screen-256color-bce tmux -u new-session -A -s main
      elif [ "$TERM_PROGRAM" == 'Apple_Terminal' ]; then
        TERM=screen-256color-bce tmux -u new-session -A -s term
      elif [ "$KITTY_WINDOW_ID" ]; then
        TERM=screen-256color-bce tmux -u new-session -A -s kitty
      fi
    elif [ "$wsl" ]; then
      tmux new-session -A -s main
    elif [ "$linux" ]; then
      if [ "$KITTY_WINDOW_ID" ]; then
        tmux -u new-session -A -s main
      else
        tmux new-session -A -s 0
      fi
    fi
  else
    TERM=screen-256color-bce tmux -u new-session -A -s "$1"
  fi
}
alias tls="tmux ls"
alias tks="tmux kill-session -t"
alias tka="tmux kill-server"
# Startup tmux
if [ ! "${TMUX+x}" ] && command -v tmux &>/dev/null; then
  if [ "$macos" ]; then
    if [ "$TERM_PROGRAM" == 'iTerm.app' ]; then
      TERM=screen-256color-bce tmux -u new-session -A -s main
    elif [ "$TERM_PROGRAM" == 'Apple_Terminal' ]; then
      TERM=screen-256color-bce tmux -u new-session -A -s term
    elif [ "$KITTY_WINDOW_ID" ]; then
      TERM=screen-256color-bce tmux -u new-session -A -s kitty
    fi
  elif [ "$wsl" ]; then
    tmux new-session -A -s main
  elif [ "$linux" ]; then
    if [ "$KITTY_WINDOW_ID" ]; then
      tmux -u new-session -A -s main
    else
      tmux new-session -A -s 0
    fi
  fi
fi

# Go # TODO: figure out how to setup go automatically
export GOROOT=/home/bokwoon/.go
export PATH=$GOROOT/bin:$PATH
export GOPATH=/home/bokwoon/go
export PATH=$GOPATH/bin:$PATH
alias g="git "

# OCaml
if echo $0 | grep -q bash; then
  :
elif echo $0 | grep -q zsh; then
  . "$HOME/.opam/opam-init/init.zsh" > /dev/null 2> /dev/null || true
fi
path-prepend "$HOME/.opam/default/bin"
if [ -d "$HOME/.opam" ]; then
  eval `opam config env`
fi

# Python
alias sv="source venv/bin/activate"
