
---
## 1. Prerequisites

**Homebrew** (macOS package manager — everything below depends on it):
```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Or download from [brew.sh](https://brew.sh).

After install, follow the printed instructions to add Homebrew to your PATH.

**jq** (JSON processor, used by scripts):
```sh
brew install jq
```

---

## 2. Terminal Setup (Optional)

Not required, but makes life significantly easier.

**iTerm2** (replaces Terminal.app — download from [iterm2.com](https://iterm2.com) or):
```sh
brew install --cask iterm2
```

### iTerm2 Dracula Theme

Install the [Dracula color theme](https://draculatheme.com/iterm) for iTerm2:
```sh
# Clone the Dracula theme
git clone https://github.com/dracula/iterm.git ~/iterm-dracula-theme
```
Then in iTerm2: **Preferences → Profiles → Colors → Color Presets → Import…** → select `~/iterm-dracula-theme/Dracula.itermcolors` → then choose **Dracula** from the Color Presets dropdown.

### iTerm2 Default Profile (restore from this repo)

A pre-configured iTerm2 profile is included in this repo at `configs/iterm2-default-profile.json`. It includes:
- **Font**: CaskaydiaCove Nerd Font Mono, 12pt (with Powerline glyphs enabled)
- **Window**: 95 columns x 35 rows
- **Status bar**: CPU, Memory, Working Directory indicators
- **Colors**: Dracula-style dark theme (bg `#282a35`, fg `#e5eaea`)

To install the font (required before importing the profile):
```sh
brew install --cask font-caskaydia-cove-nerd-font
```

To import the profile, copy it to iTerm2's Dynamic Profiles directory:
```sh
cp configs/iterm2-default-profile.json ~/Library/Application\ Support/iTerm2/DynamicProfiles/
```
Restart iTerm2. The profile will appear automatically. To make it the default:
**Preferences → Profiles** → select **Default** → click **Other Actions…** → **Set as Default**.

**Oh My Zsh** (plugin framework):
```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

**Powerlevel10k + Zsh plugins** (prompt theme, syntax coloring, autocomplete from history, substring search):
```sh
brew install powerlevel10k zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search
```

Add to the **bottom** of `~/.zshrc`:
```sh
# Powerlevel10k
source /opt/homebrew/opt/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Zsh plugins
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey '^[OA' history-substring-search-up
bindkey '^[OB' history-substring-search-down
```

Reload and configure the prompt:
```sh
source ~/.zshrc
p10k configure
```

**Recommended Oh My Zsh plugins** — add to `plugins=(...)` in `~/.zshrc`:
```sh
plugins=(git terraform kubectl z colored-man-pages)
```

---

## 3. Neovim Setup

Your full Neovim config is stored in this repo under `configs/nvim/`. It includes LSP, Treesitter, Telescope, autocompletion (nvim-cmp), lualine, defx file explorer, and the NeoSolarized color scheme.

### Install Neovim
```sh
brew install neovim
```

### Install vim-plug (plugin manager)
```sh
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
```

### Copy config files from this repo
```sh
# Remove any existing nvim config
rm -rf ~/.config/nvim

# Copy the config from this repo
cp -r configs/nvim ~/.config/nvim
```

### Install plugins
Open Neovim and run:
```
:PlugInstall
```

### Install LSP servers
After plugins are installed, open Neovim and run:
```
:LspInstall tsserver
:LspInstall diagnosticls
:LspInstall flow
```
Or use `:LspInstallInfo` to browse and install language servers interactively.

### Dependencies
Some plugins require external tools:
```sh
# Treesitter needs a C compiler
xcode-select --install

# For telescope live_grep
brew install ripgrep

# For eslint/prettier formatting
npm install -g eslint_d prettier_d_slim
```

### .vimrc (optional, for vanilla vim fallback)
If you also use vim, create `~/.vimrc`:
```vim
filetype plugin indent on
packadd! dracula
syntax enable
colorscheme dracula
syntax on
set showmatch
set ruler
set smarttab
set shiftwidth=4
set tabstop=4
```

---

## 4. AWS CLI + Session Manager Plugin

```sh
brew install awscli
```

Install the [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html):
```sh
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac_arm64/sessionmanager-bundle.zip" \
  -o "sessionmanager-bundle.zip"
unzip sessionmanager-bundle.zip
sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
rm -rf sessionmanager-bundle sessionmanager-bundle.zip
```

---

