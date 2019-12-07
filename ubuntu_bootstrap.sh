#!/bin/bash

add_ppa() {
	[ ! "$(grep -q "^deb .*$1" /etc/apt/sources.list.d/*)" ] && sudo add-apt-repository -y "ppa:$1"
}
add_ppa jonathonf/vim
add_ppa ubuntu-elisp/ppa
sudo apt-get update 

mkdir -p "$HOME/local/bin"
[ ! "$(echo ":$PATH:" | grep ":$HOME/local/bin:" )" ] && echo 'PATH="$HOME/local/bin:$PATH"' >> "$HOME/.bashrc"
exec "$BASH" # Reload bash

if ! command -v curl >/dev/null 2>&1; then sudo apt-get install curl; fi
sudo apt-get install -y git tmux zsh vim emacs silversearcher-ag
if ! command -v nvim >/dev/null 2>&1; then
	curl -Lo /tmp/nvim.appimage https://github.com/neovim/neovim/releases/download/stable/nvim.appimage
	chmod a+x /tmp/nvim.appimage
	if [ "$WSL_DISTRO_NAME" ]; then
		/tmp/nvim.appimage --appimage-extract && mv squashfs-root "$HOME/local/nvim" && ln -s "$HOME/local/nvim/AppRun" "$HOME/local/bin/nvim"
	else
		mv /tmp/nvim.appimage "$HOME/local/bin/nvim"
	fi
fi
sudo apt-get install -y emacs-snapshot # from ubuntu-elisp/ppa
if command -v emacs-snapshot >/dev/null 2>&1 && [ "$(command -v emacs-snapshot)" != "$(command -v emacs)" ]; then
	ln -s "$(command -v emacs-snapshot)" "$HOME/local/bin/emacs"
fi
if ! command -v fzf >/dev/null 2>&1; then
	git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
	printf 'y\ny\ny\n' | "$HOME/.fzf/install"
fi

# Programming languages
if ! command -v node >/dev/null 2>&1; then
	curl -sL https://deb.nodesource.com/setup_13.x | sudo -E bash -
	sudo apt-get install -y nodejs
fi
! command -v go >/dev/null 2>&1 && curl https://raw.githubusercontent.com/canha/golang-tools-install-script/master/goinstall.sh | bash
! command -v rustc >/dev/null 2>&1 && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# gitconfig aliases
if command -v git >/dev/null 2>&1; then
	[ ! "$(git config --list | grep alias.facpush)" ] && sudo bash -c "$(curl https://raw.githubusercontent.com/bokwoon95/setup/master/gitconfig.sh)"
fi
# grepf and rgrepf
! command -v grepf >/dev/null 2>&1 && sudo bash -c "$(curl https://raw.githubusercontent.com/bokwoon95/grepf/master/install)"

# QoL
sudo apt-get install -y ffmpeg youtube-dl asciinema imagemagick cmus weechat build-essential
