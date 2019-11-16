#!/bin/bash

[ "$(echo "$@" | grep 'xcode')" ]         && Xcode='true'
[ "$(echo "$@" | grep 'defaults')" ]      && Defaults='true'
[ "$(echo "$@" | grep 'homebrew')" ]      && Homebrew='true'
[ "$(echo "$@" | grep 'homebrew_opts')" ] && Homebrew_Opts='true'
[ "$(echo "$@" | grep 'apps')" ]          && Apps='true'
[ "$(echo "$@" | grep 'symlinks')" ]      && Symlinks='true'

if [ $# -eq 0 ]; then
  echo '   xcode'
  echo '   defaults'
  echo '   homebrew'
  echo '   homebrew_opts'
  echo '   apps'
  echo '   symlinks'
fi

mkdir -p "$HOME/local/bin"
export PATH="$PATH:$HOME/local/bin"
if [ -d /usr/local/bin ] && ([ ! -r /usr/local/bin ] || [ ! -w /usr/local/bin ]); then
  sudo chmod u+rw /usr/local/bin
fi

if [ "$Xcode" ] || ! command -v git >/dev/null 2>&1; then
  printf 'Installing jq1.6... '
  curl -sSLO https://github.com/bokwoon95/dotfiles/raw/master/bin/jq1.6 &&
    chmod a+x jq1.6 &&
    mv jq1.6 "$HOME/local/bin"
  if ! command -v jq1.6 >/dev/null 2>&1; then
    echo 'jq1.6 was not installed successfully, aborting'
    exit 1
  fi
  printf 'done\n'

  printf 'Installing pup0.4... '
  curl -sSLO https://github.com/bokwoon95/dotfiles/raw/master/bin/pup0.4 &&
    chmod a+x pup0.4 &&
    mv pup0.4 "$HOME/local/bin"
  if ! command -v pup0.4 >/dev/null 2>&1; then
    echo 'pup0.4 was not installed successfully, aborting'
    exit 1
  fi
  printf 'done\n'

  printf 'Installing paralel... '
  curl -sSLO https://github.com/bokwoon95/dotfiles/raw/master/bin/paralel &&
    chmod a+x paralel &&
    mv paralel "$HOME/local/bin"
  if ! command -v paralel >/dev/null 2>&1; then
    echo 'paralel was not installed successfully, aborting'
    exit 1
  fi
  printf 'done\n'

  xcodeclt_url="$(
    curl -sSL https://api.github.com/repos/bokwoon95/dotfiles/releases/latest |
      jq1.6 -r '.assets[].browser_download_url' |
      grep -i 'xcode.*\.dmg'
  )"
  xcodeclt_filename="$(echo $xcodeclt_url | awk -F/ '{print $NF}')"
  echo "Installing $xcodeclt_filename... "
  curl -L "$xcodeclt_url" -o "$HOME/Downloads/$xcodeclt_filename" &&
    open "$HOME/Downloads/$xcodeclt_filename"
  exit 0
fi

if [ "$SHELL" = '/bin/bash' ]; then
  echo 'Changing default shell to zsh'
  chsh -s $(which zsh)
  echo 'Accepting Xcode license'
  sudo xcodebuild -license accept
  echo 'Unhiding /Volumes'
  sudo chflags nohidden /Volumes
fi

if [ "$Defaults" ]; then
  printf 'Setting macOS defaults... '
  # Set macOS defaults
  osascript -e 'tell application "System Preferences" to quit'
  chflags nohidden ~/Library
  # Global
  defaults write -g InitialKeyRepeat -int 15 # normal minimum is 15 (225 ms)
  defaults write -g KeyRepeat -int 1 # normal minimum is 2 (30 ms)
  defaults write -g QLPanelAnimationDuration -float 0 # disable quicklook animations
  # Avoid creating .DS_Store files on network or USB volumes
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
  defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
  # Accessibility
  defaults write com.apple.universalaccess reduceTransparency -bool true
  # Enable snap-to-grid for icon view
  /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
  /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
  /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
  # NSGlobalDomain
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
  defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
  defaults write NSGlobalDomain _HIHideMenuBar -bool true
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
  # Finder
  defaults write com.apple.finder QLEnableTextSelection -bool true
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder _FXSortFoldersFirst -bool true
  defaults write com.apple.finder WarnOnEmptyTrash -bool false
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
  killall Finder
  # Dock
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 0
  defaults write com.apple.dock autohide-time-modifier -float 0
  defaults write com.apple.dock dashboard-in-overlay -bool false
  defaults write com.apple.dock expose-animation-duration -float 0
  defaults write com.apple.dock launchanim -bool false
  defaults write com.apple.dock mineffect -string "scale"
  defaults write com.apple.dock mru-spaces -bool false
  defaults write com.apple.dock persistent-apps -array
  defaults write com.apple.dock persistent-others -array
  defaults write com.apple.dock show-process-indicators -bool false
  defaults write com.apple.dock show-recents -bool false
  defaults write com.apple.dock showAppExposeGestureEnabled -bool true
  defaults write com.apple.dock showhidden -bool true
  killall Dock
  # Safari
  defaults write com.apple.Safari AutoOpenSafeDownloads -bool false
  killall Safari >/dev/null 2>&1 ||:
  # Mail
  defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false
  killall Mail >/dev/null 2>&1 ||:
  printf 'done\n'
fi

if [ "$Apps" ]; then
  # Dropbox
  if [ ! -d '/Applications/Dropbox.app' ]; then
    apps+=('https://www.dropbox.com/download?plat=mac&full=1''|dropbox.dmg')
  fi

  # iTerm2
  if [ ! -d '/Applications/iTerm.app' ]; then
    printf 'curling iTerm2 url... '
    version_dots_to_underscores="$(
      curl -sSL https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/iterm2.rb |
        grep -E 'version '\''.+'\''' -m1 |
        sed -nE 's#version '\''(.+)'\''#\1#p' |
        tr '.' '_' |
        xargs
    )"
    format="https://iterm2.com/downloads/stable/iTerm2-$version_dots_to_underscores.zip"
    apps+=("$format")
    printf 'done\n'
  fi

  # MacVim
  if [ ! -d '/Applications/MacVim.app' ]; then
    printf 'curling MacVim url... '
    apps+=("$(
        curl -sSL https://api.github.com/repos/macvim-dev/macvim/releases/latest |
          jq1.6 -r '.assets[].browser_download_url' |
          grep \.dmg
      )")
    printf 'done\n'
  fi

  # osxfuse
  printf 'curling osxfuse url... '
  apps+=("$(
      curl -sSL https://api.github.com/repos/osxfuse/osxfuse/releases/latest |
        jq1.6 -r '.assets[].browser_download_url' |
        grep \.dmg
    )")
  printf 'done\n'

  # Box Sync
  if [ ! -d '/Applications/Box Sync.app' ]; then
    apps+=('https://e3.boxcdn.net/box-installers/sync/Sync+4+External/Box%20Sync%20Installer.dmg')
  fi

  # Disk Inventory X
  if [ ! -d '/Applications/Disk Inventory X.app' ]; then
    apps+=('http://www.derlien.com/download.php?file=DiskInventoryX''|disk_inventory_x.dmg')
  fi

  # Google Chrome
  if [ ! -d '/Applications/Google Chrome.app' ]; then
    apps+=('https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg')
  fi

  # Firefox
  if [ ! -d '/Applications/Firefox.app' ]; then
    printf 'curling Firefox url... '
    version="$(
      curl -sSL https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/firefox.rb |
        grep -E 'version '\''.+'\''' -m1 |
        sed -nE 's#version '\''(.+)'\''#\1#p' |
        xargs
    )"
    format="https://download-installer.cdn.mozilla.net/pub/firefox/releases/$version/mac/en-GB/Firefox%20$version.dmg"
    apps+=("$format")
    printf 'done\n'
  fi

  # WhatsApp
  if [ ! -d '/Applications/WhatsApp.app' ]; then
    printf 'curling WhatsApp url... '
    version="$(
      curl -sSL https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/whatsapp.rb |
        grep -E 'version '\''.+'\''' -m1 |
        sed -nE 's#version '\''(.+)'\''#\1#p' |
        xargs
    )"
    format="https://web.whatsapp.com/desktop/mac/files/release-$version.zip"
    apps+=("$format")
    printf 'done\n'
  fi

  # Kitty
  if [ ! -d '/Applications/kitty.app' ]; then
    printf 'curling Kitty url... '
    apps+=("$(
        curl -sSL https://api.github.com/repos/kovidgoyal/kitty/releases/latest |
          jq1.6 -r '.assets[].browser_download_url' |
          grep \.dmg
      )")
    printf 'done\n'
  fi

  # Folx
  if [ ! -d '/Applications/Folx.app' ]; then
    apps+=('https://cdn.eltima.com/download/downloader_mac.dmg')
  fi

  # Handbrake
  if [ ! -d '/Applications/HandBrake.app' ]; then
    printf 'curling Handbrake url... '
    version="$(
      curl -sSL https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/handbrake.rb |
        grep -E 'version '\''.+'\''' -m1 |
        sed -nE 's#version '\''(.+)'\''#\1#p' |
        xargs
    )"
    format="https://download.handbrake.fr/handbrake/releases/$version/HandBrake-$version.dmg"
    apps+=("$format")
    printf 'done\n'
  fi

  # RCDefaultApp
  apps+=('http://www.rubicode.com/Downloads/RCDefaultApp-2.1.X.dmg')

  # VLC
  if [ ! -d '/Applications/VLC.app' ]; then
    printf 'curling VLC url... '
    version="$(
      curl -sSL https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/vlc.rb |
        grep -E 'version '\''.+'\''' -m1 |
        sed -nE 's#version '\''(.+)'\''#\1#p' |
        xargs
    )"
    format="https://get.videolan.org/vlc/$version/macosx/vlc-$version.dmg"
    apps+=("$format")
    printf 'done\n'
  fi

  # Dash
  if [ ! -d '/Applications/Dash.app' ]; then
    printf 'curling Dash url... '
    version_major="$(
      curl -sSL https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/dash.rb |
        grep -E 'version '\''.+'\''' -m1 |
        sed -nE 's#version '\''(.+)'\''#\1#p' |
        awk -F. '{print $1}' |
        xargs
    )"
    format="https://kapeli.com/downloads/v$version_major/Dash.zip"
    apps+=("$format")
    printf 'done\n'
  fi

  # KeyCastr
  if [ ! -d '/Applications/KeyCastr.app' ]; then
    printf 'curling KeyCastr url... '
    version="$(
      curl -sSL https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/keycastr.rb |
        grep -E 'version '\''.+'\''' -m1 |
        sed -nE 's#version '\''(.+)'\''#\1#p' |
        xargs
    )"
    format="https://github.com/keycastr/keycastr/releases/download/v$version/KeyCastr.app.zip"
    apps+=("$format")
    printf 'done\n'
  fi

  # ngrok
  if ! command -v ngrok >/dev/null 2>&1; then
    printf 'curling ngrok url... '
    apps+=("$(
        curl -sSL https://ngrok.com/download |
          pup0.4 '#dl-darwin-amd64 attr{href}'
      )")
    printf 'done\n'
  fi

  # Opera
  if [ ! -d '/Applications/Opera.app' ]; then
    printf 'curling Opera url... '
    version="$(
      curl -sSL https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/opera.rb |
        grep -E 'version '\''.+'\''' -m1 |
        sed -nE 's#version '\''(.+)'\''#\1#p' |
        xargs
    )"
    format="https://get.geo.opera.com/pub/opera/desktop/$version/mac/Opera_$version""_Setup.dmg"
    apps+=("$format")
    printf 'done\n'
  fi

  # Microsoft Office
  if [ ! -d '/Applications/Microsoft Word.app' ]; then
    open "https://www.office.com/?auth=2&home=1"
  fi

  # Contexts
  if [ ! -d '/Applications/Contexts.app' ]; then
    printf 'curling Contexts url... '
    version="$(
      curl -sSL https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/contexts.rb |
        grep -E 'version '\''.+'\''' -m1 |
        sed -nE 's#version '\''(.+)'\''#\1#p' |
        xargs
    )"
    format="https://contexts.co/releases/Contexts-$version.dmg"
    apps+=("$format")
    printf 'done\n'
  fi

  # Hammerspoon
  if [ ! -d '/Applications/Hammerspoon.app' ]; then
    printf 'curling Hammerspoon url... '
    apps+=("$(
        curl -sSL https://api.github.com/repos/Hammerspoon/hammerspoon/releases/latest |
          jq1.6 -r '.assets[].browser_download_url'
      )")
    printf 'done\n'
  fi

  # Julia
  if ! test -n "$(find /Applications -maxdepth 1 -name 'Julia*.app' -print -quit)"; then
    printf 'curling Julia url... '
    apps+=("$(
        curl -sSL https://julialang.org/downloads/ |
          grep -oE 'href=".*\.dmg"' |
          sed -n 's#href="\(.*\)"#\1#p' |
          head -1
      )")
    printf 'done\n'
  fi

  # Golang
  if ! command -v go >/dev/null 2>&1; then
    printf 'curling Golang url... '
    apps+=("$(
        curl -sSL https://golang.org/dl/ |
          grep -oE 'href=".*darwin-amd64.*\.pkg"' |
          sed -n 's#href="\(.*\)"#\1#p' |
          head -1
      )")
    printf 'done\n'
  fi

  # Wireshark
  if [ ! -d '/Applications/Wireshark.app' ]; then
    printf 'curling Wireshark url... '
    apps+=("$(
        curl -sSL https://www.wireshark.org/download.html |
          grep -oE 'href=".*\.dmg"' |
          sed 's#href="\(.*\)"#\1#p' |
          sed 's# #%20#g' |
          head -1
      )")
    printf 'done\n'
  fi

  # Duet
  if [ ! -d '/Applications/duet.app' ]; then
    printf 'curling Duet url... '
    version="$(
      curl -sSL https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/duet.rb |
        grep -E 'version '\''.+'\''' -m1 |
        sed -nE 's#version '\''(.+)'\''#\1#p' |
        xargs
    )"
    version_major="$(echo "$version" | awk -F. '{print $1}')"
    version_minor="$(echo "$version" | awk -F. '{print $2}')"
    version_dots_to_hyphens="$(echo "$version" | tr '.' '-')"
    format="https://duet.nyc3.cdn.digitaloceanspaces.com/Mac/$version_major\_$version_minor/duet-$version_dots_to_hyphens.zip"
    apps+=("$format")
    printf 'done\n'
  fi

  # IINA
  if [ ! -d '/Applications/IINA.app' ]; then
    printf 'curling Iina url... '
    version="$(
      curl -sSL https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/iina.rb |
        grep -E 'version '\''.+'\''' -m1 |
        sed -nE 's#version '\''(.+)'\''#\1#p' |
        xargs
    )"
    format="https://dl-portal.iina.io/IINA.v$version.dmg"
    apps+=("$format")
    printf 'done\n'
  fi

  # Docker
  if [ ! -d '/Applications/Docker.app' ]; then
    printf 'curling Docker url... '
    apps+=("$(
        curl -sSL https://docs.docker.com/docker-for-mac/release-notes/ |
          grep -oE 'href=".*\.dmg"' |
          sed -n 's#href="\(.*\)"#\1#p' |
          head -1
      )")
    printf 'done\n'
  fi

  # Skim
  if [ ! -d '/Applications/Skim.app' ]; then
    printf 'curling Skim url... '
    format="$(
      curl -sSL https://skim-app.sourceforge.io |
        pup0.4 'a:contains("Download") attr{href}' |
        grep '\.dmg' |
        xargs
    )|skim.dmg"
    apps+=("$format")
    printf 'done\n'
  fi

  # Generate downloads.txt
  printf "%s\n" "${apps[@]}" | tee downloads.txt

  mkdir -p ~/Downloads/temp
  dl_paralel() {
    local url filename
    if [ "$(echo "$1" | grep '|')" ]; then
      url="$(echo "$1" | cut -d'|' -f1)"
      filename="$(echo "$1" | cut -d'|' -f2)"
      curl -sSL "$url" -o "$HOME/Downloads/temp/$filename"
    elif [ "$1" ]; then
      filename="$(echo "$1" | awk -F/ '{print $NF}')"
      curl -sSL "$1" -o "$HOME/Downloads/temp/$filename"
    fi
    extension="$(echo "$filename" | awk -F. '{print $NF}')"
    if [ "$extension" = 'zip' ]; then
      unzip -qq "$HOME/Downloads/temp/$filename" -d "$HOME/Downloads/temp/" &&
        mv "$HOME/Downloads/temp/$filename" ~/.Trash
    fi
  }
  dl_xargs() {
    local url filename
    if [ "$(echo "$1" | grep '|')" ]; then
      url="$(echo "$1" | cut -d'|' -f1)"
      filename="$(echo "$1" | cut -d'|' -f2)"
      echo "[DOWNLOADING] $filename"
      curl -sSL "$url" -o "$HOME/Downloads/temp/$filename"
      echo "[FINISHED] $filename"
    elif [ "$1" ]; then
      filename="$(echo "$1" | awk -F/ '{print $NF}')"
      echo "[DOWNLOADING] $filename"
      curl -sSL "$1" -o "$HOME/Downloads/temp/$filename"
      echo "[FINISHED] $filename"
    fi
    extension="$(echo "$filename" | awk -F. '{print $NF}')"
    if [ "$extension" = 'zip' ]; then
      unzip -qq "$HOME/Downloads/temp/$filename" -d "$HOME/Downloads/temp/" &&
        mv "$HOME/Downloads/temp/$filename" ~/.Trash
    fi
  }
  export -f dl_paralel
  export -f dl_xargs
  if command -v perl >/dev/null 2>&1 && command -v paralel >/dev/null 2>&1; then
    Paralel='true'
  fi
  open ~/Downloads/temp
  if [ "$Parallel" ]; then
    < downloads.txt paralel -j30 --bar 'dl_paralel {}'
  else
    < downloads.txt xargs -I{} -P30 -- bash -c 'dl_xargs "{}"'
  fi
fi

if [ "$Homebrew" ]; then
  PACKAGES=(tmux
    vim
    neovim
    emacs
    fzf
    the_silver_searcher
    python3
    ffmpeg
    youtube-dl
    asciinema
    imagemagick
    rmtrash
    cmus
    bat
    ruby
    rbenv
    yarn
  )

  echo 'Checking for Homebrew...'
  if test ! $(which brew); then
    echo 'Installing homebrew...'
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  brew install ${PACKAGES[@]} ||:
fi

if [ "$Homebrew_Opts" ]; then
  OPT_PACKAGES=(wget
    cmus-control
    tig
    weechat
    figlet
    fd
    rlwrap
    mit-scheme
    cmake
    sshfs
    unison
    pass
    hub
  )

  echo 'Checking for Homebrew...'
  if test ! $(which brew); then
    echo 'Installing homebrew...'
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  brew tap thefox/brewery
  brew tap railwaycat/emacsmacport
  brew install ${OPT_PACKAGES[@]} ||:
  brew services start thefox/brewery/cmus-control
  # brew install emacs-mac # osxfuse needed
fi

if command -v git >/dev/null 2>&1 && [ "$Symlinks" ]; then
  if [ ! -d "$HOME/.vim" ]; then
    git clone https://github.com/bokwoon95/.vim ~/.vim
  fi
  if [ ! -d "$HOME/.emacs.d" ]; then
    git clone https://github.com/bokwoon95/.emacs.d ~/.emacs.d
  fi
  if [ ! -d "$HOME/.zsh/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
  fi
  if [ ! -d "$HOME/.tmux" ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  fi

  # ~/.zshrc
  if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    echo "existing ~/.zshrc found, renaming it to ~/.zshrc.bak"
    rm ~/.zshrc.bak
    mv ~/.zshrc ~/.zshrc.bak
  fi
  if [ -L "$HOME/.zshrc" ]; then
    unlink ~/.zshrc
  fi
  ln -s ~/.vim/.zshrc ~/.zshrc && echo "symlinked ~/.zshrc@"

  # ~/.bashrc
  if [ -f "$HOME/.bashrc" ] && [ ! -L "$HOME/.bashrc" ]; then
    echo "existing ~/.bashrc found, renaming it to ~/.bashrc.bak"
    rm ~/.bashrc.bak
    mv ~/.bashrc ~/.bashrc.bak
  fi
  if [ -L "$HOME/.bashrc" ]; then
    unlink ~/.bashrc
  fi
  ln -s ~/.vim/.bashrc ~/.bashrc && echo "symlinked ~/.bashrc@"

  # ~/.tmux.conf
  if [ -f "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; then
    echo "existing ~/.tmux.conf found, renaming it to ~/.tmux.conf.bak"
    rm ~/.tmux.conf.bak
    mv ~/.tmux.conf ~/.tmux.conf.bak
  fi
  if [ -L "$HOME/.tmux.conf" ]; then
    unlink ~/.tmux.conf
  fi
  ln -s ~/.vim/.tmux.conf ~/.tmux.conf && echo "symlinked ~/.tmux.conf@"

  # ~/.config/nvim/init.vim
  mkdir -p ~/.config/nvim/
  if [ -f "$HOME/.config/nvim/init.vim" ] && [ ! -L "$HOME/.config/nvim/init.vim" ]; then
    echo "existing ~/config/nvim/init.vim found, renaming it to ~/config/nvim/init.vim.bak"
    rm ~/config/nvim/init.vim.bak
    mv ~/config/nvim/init.vim ~/config/nvim/init.vim.bak
  fi
  if [ -L "$HOME/.config/nvim/init.vim" ]; then
    unlink ~/.config/nvim/init.vim
  fi
  ln -s ~/.vim/vimrc ~/.config/nvim/init.vim && echo "symlinked ~/.config/nvim/init.vim@"

  # ~/.config/nvim/after
  if [ -d "$HOME/.config/nvim/after" ] && [ ! -L "$HOME/.config/nvim/after" ]; then
    echo "existing ~/config/nvim/after found, renaming it to ~/config/nvim/after.bak"
    rm -rf ~/config/nvim/after.bak
    mv ~/config/nvim/after ~/config/nvim/after.bak
  fi
  if [ -L "$HOME/.config/nvim/after" ]; then
    unlink ~/.config/nvim/after
  fi
  ln -s ~/.vim/after ~/.config/nvim/after && echo "symlinked ~/.config/nvim/after@"

  # ~/.gitignore
  if [ -f "$HOME/.gitignore" ] && [ ! -L "$HOME/.gitignore" ]; then
    echo "existing ~/.gitignore found, renaming it to ~/.gitignore.bak"
    rm ~/.gitignore.bak
    mv ~/.gitignore ~/.gitignore.bak
  fi
  if [ -L "$HOME/.gitignore" ]; then
    unlink ~/.gitignore
  fi
  ln -s ~/.vim/gitignore-mac ~/.gitignore && echo "symlinked ~/.gitignore@"

  # ~/.hammerspoon/init.lua
  if [ -f "$HOME/.hammerspoon/init.lua" ] && [ ! -L "$HOME/.hammerspoon/init.lua" ]; then
    echo "existing ~/.hammerspoon/init.lua found, renaming it to ~/.hammerspoon/init.lua.bak"
    rm ~/.hammerspoon/init.lua.bak
    mv ~/.hammerspoon/init.lua ~/.hammerspoon/init.lua.bak
  fi
  mkdir -p ~/.hammerspoon
  if [ -L "$HOME/.hammerspoon/init.lua" ]; then
    unlink ~/.hammerspoon/init.lua
  fi
  ln -s ~/.vim/init.lua ~/.hammerspoon/init.lua && echo "symlinked ~/.hammerspoon/init.lua@"

  # ~/.local/bin/
  if [ ! -d "$HOME/.local/bin/" ]; then
    mkdir -p ~/.local/bin
  fi

  # ~/.local/bin/sshrc
  if [ -f "$HOME/.local/bin/sshrc" ] && [ ! -L "$HOME/.local/bin/sshrc" ]; then
    echo "existing ~/.local/bin/sshrc found, renaming it to ~/.local/bin/sshrc.bak"
    rm ~/.local/bin/sshrc.bak
    mv ~/.local/bin/sshrc ~/.local/bin/sshrc.bak
  fi
  if [ -L "$HOME/.local/bin/sshrc" ]; then
    unlink ~/.local/bin/sshrc
  fi
  ln -s ~/.vim/sshrc ~/.local/bin/sshrc && echo "symlinked ~/.local/bin/sshrc@"

  # ~/.config/nvim/Ultisnips
  if [ -f "$HOME/.config/nvim/Ultisnips" ] && [ ! -L "$HOME/.config/nvim/Ultisnips" ]; then
    echo "existing ~/.config/nvim/Ultisnips found, renaming it to ~/.config/nvim/Ultisnips.bak"
    rm ~/.config/nvim/Ultisnips.bak
    mv ~/.config/nvim/Ultisnips ~/.config/nvim/Ultisnips.bak
  fi
  if [ -L "$HOME/.config/nvim/Ultisnips" ]; then
    unlink ~/.config/nvim/Ultisnips
  fi
  ln -s ~/.vim/Ultisnips ~/.config/nvim/Ultisnips && echo "symlinked ~/.config/nvim/Ultisnips@"

  # ~/.config/cmus/rc
  mkdir -p ~/.config/cmus/
  if [ -f "$HOME/.config/cmus/rc" ] && [ ! -L "$HOME/.config/cmus/rc" ]; then
    echo "existing ~/.config/cmus/rc found, renaming it to ~/.config/cmus/rc.bak"
    rm ~/.config/cmus/rc.bak
    mv ~/.config/cmus/rc ~/.config/cmus/rc.bak
  fi
  if [ -L "$HOME/.config/cmus/rc" ]; then
    unlink ~/.config/cmus/rc
  fi
  ln -s ~/.vim/cmusrc ~/.config/cmus/rc && echo "symlinked ~/.config/cmus/rc@"

  # ~/.config/kitty/kitty.conf
  mkdir -p ~/.config/kitty
  if [ ! -f "$HOME/.config/kitty/kitty.conf" ]; then
    echo "copying ~/.vim/kitty.conf to ~/.config/kitty/kitty.conf"
    cp ~/.vim/kitty.conf ~/.config/kitty/kitty.conf
  fi

  # ~/.config/flake8
  if [ -f "$HOME/.config/flake8" ] && [ ! -L "$HOME/.config/flake8" ]; then
    echo "existing ~/.config/flake8 found, renaming it to ~/.config/flake8.bak"
    rm ~/.config/flake8.bak
    mv ~/.config/flake8 ~/.config/flake8.bak
  fi
  mkdir -p ~/.config
  if [ -L "$HOME/.config/flake8" ]; then
    unlink ~/.config/flake8
  fi
  ln -s ~/.vim/flake8 ~/.config/flake8 && echo "symlinked ~/.config/flake8@"
fi
