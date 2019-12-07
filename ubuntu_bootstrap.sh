#!/bin/bash

add_ppa() {
  if [ ! "$(ls -A /etc/apt/sources.list.d/)" ] || grep -q "^deb .*$1" /etc/apt/sources.list.d/*; then
    sudo add-apt-repository -y "ppa:$1"
  fi
}
add_ppa jonathonf/vim
add_ppa ubuntu-elisp/ppa
sudo apt-get update 

mkdir -p "$HOME/local/bin"

if ! command -v curl &>/dev/null; then sudo apt-get install -y curl; fi
sudo apt-get install -y git tmux zsh vim emacs silversearcher-ag
if ! command -v nvim &>/dev/null; then
  curl -Lo /tmp/nvim.appimage https://github.com/neovim/neovim/releases/download/stable/nvim.appimage
  chmod a+x /tmp/nvim.appimage
  if [ "$WSL_DISTRO_NAME" ]; then
    /tmp/nvim.appimage --appimage-extract && mv squashfs-root "$HOME/local/nvim" && ln -s "$HOME/local/nvim/AppRun" "$HOME/local/bin/nvim"
  else
    mv /tmp/nvim.appimage "$HOME/local/bin/nvim"
  fi
fi
sudo apt-get install -y emacs-snapshot # from ubuntu-elisp/ppa
if command -v emacs-snapshot &>/dev/null && [ -L "$HOME/local/bin/emacs" ]; then
  unlink "$HOME/local/bin/emacs"
  ln -s "$(command -v emacs-snapshot)" "$HOME/local/bin/emacs"
fi
if command -v git &>/dev/null && ! command -v fzf &>/dev/null; then
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  printf 'y\ny\ny\n' | "$HOME/.fzf/install"
fi

# dotfiles
symlink() {
  local source="$1"
  local dest="$2"
  local destdir="$(echo "$dest" | sed 's#\(.*\)/.*#\1#')"
  mkdir -p "$destdir"
  if [ -f "$dest" ] && [ ! -L "$dest" ]; then
    echo "existing $dest found, renaming it to $dest.bak"
    rm "$dest.bak"
    mv "$dest" "$dest.bak"
  fi
  [ -L "$dest" ] && unlink "$dest"
  ln -s "$source" "$dest" && echo "symlinked $dest@"
}
dothome="$HOME/dotfiles"
[ ! -d "$dothome" ] && git clone https://github.com/bokwoon95/dotfiles "$dothome"
symlink "$dothome/.zshrc" "$HOME/.zshrc"
symlink "$dothome/.zshrc" "$HOME/.bashrc"
symlink "$dothome/.tmux.conf" "$HOME/.tmux.conf"
symlink "$dothome/.tigrc" "$HOME/.tigrc"
symlink "$dothome/.psqlrc" "$HOME/.psqlrc"
symlink "$dothome/.inputrc" "$HOME/.inputrc"
symlink "$dothome/cmusrc" "$HOME/.config/cmus/rc"
symlink "$dothome/gitignore" "$HOME/.gitignore"
[ ! -d "$HOME/.vim" ] && git clone https://github.com/bokwoon95/.vim "$HOME/.vim"
symlink "$HOME/.vim/vimrc" "$HOME/.config/nvim/init.vim"
symlink "$HOME/.vim/after/" "$HOME/.config/nvim/"
symlink "$HOME/.vim/Ultisnips/" "$HOME/.config/nvim/"
[ ! -d "$HOME/.emacs.d" ] && git clone https://github.com/bokwoon95/.emacs.d "$HOME/.emacs.d"
[ ! -d "$HOME/.zsh/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.zsh/zsh-autosuggestions"
[ ! -d "$HOME/.tmux/plugins/tpm" ] && git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

# gitconfig aliases
! git config --list | grep -q alias.facpush && sudo bash -c "$(curl https://raw.githubusercontent.com/bokwoon95/setup/master/gitconfig.sh)"
# grepf and rgrepf
! command -v grepf &>/dev/null && sudo bash -c "$(curl https://raw.githubusercontent.com/bokwoon95/grepf/master/install)"

# Programming languages
if ! command -v node &>/dev/null; then
  curl -sL https://deb.nodesource.com/setup_13.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi
! command -v go &>/dev/null && curl https://raw.githubusercontent.com/canha/golang-tools-install-script/master/goinstall.sh | bash
! command -v rustc &>/dev/null && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# QoL
sudo apt-get install -y ffmpeg youtube-dl asciinema imagemagick cmus weechat build-essential
