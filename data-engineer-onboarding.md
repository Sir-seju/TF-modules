
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

## 3. AWS CLI + Session Manager Plugin

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

