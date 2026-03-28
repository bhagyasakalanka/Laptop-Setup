#!/bin/bash
set -e

# ===============================
# Parse input
# ===============================
ACTION=""
while getopts "a:" opt; do
  case $opt in
    a) ACTION=$OPTARG ;;
    *) echo "Usage: $0 [-a fe|be|basic|full]" >&2; exit 1 ;;
  esac
done

echo "===== Mac Dev Setup Started ====="
echo "Profile selected: ${ACTION:-interactive}"

# ===============================
# Flags for optional features
# ===============================
INSTALL_ITERM=false
INSTALL_OH_MY_ZSH=false
INSTALL_POWERLEVEL10K=false
GENERATE_SSH=false
CONFIGURE_MACOS=false
INTERACTIVE=true

# ===============================
# Profile-based decisions
# ===============================
case "$ACTION" in
  fe)
    echo "Setting up Frontend developer tools..."
    INSTALL_ITERM=true
    INSTALL_OH_MY_ZSH=true
    INTERACTIVE=false
    ;;
  be)
    echo "Setting up Backend developer tools..."
    INSTALL_ITERM=true
    INSTALL_OH_MY_ZSH=true
    INSTALL_POWERLEVEL10K=true
    INTERACTIVE=false
    ;;
  basic)
    echo "Installing basic tools only..."
    INTERACTIVE=false
    ;;
  full)
    echo "Installing everything..."
    INSTALL_ITERM=true
    INSTALL_OH_MY_ZSH=true
    INSTALL_POWERLEVEL10K=true
    CONFIGURE_MACOS=true
    INTERACTIVE=false
    ;;
  *)
    echo "No profile provided. Using interactive mode..."
    INTERACTIVE=true
    ;;
esac

# ===============================
# Collect all optional prompts upfront
# (interactive mode only — avoid mid-script interruptions)
# ===============================
if [[ "$INTERACTIVE" == true ]]; then
    echo ""
    echo "--- Optional Features ---"
    read -p "Install iTerm2? (y/n): " answer;           [[ "$answer" == "y" ]] && INSTALL_ITERM=true
    read -p "Install Oh My Zsh? (y/n): " answer;        [[ "$answer" == "y" ]] && INSTALL_OH_MY_ZSH=true
    read -p "Generate SSH key? (y/n): " answer;         [[ "$answer" == "y" ]] && GENERATE_SSH=true
    read -p "Apply macOS settings? (y/n): " answer;     [[ "$answer" == "y" ]] && CONFIGURE_MACOS=true
    read -p "Install Powerlevel10k? (y/n): " answer;    [[ "$answer" == "y" ]] && INSTALL_POWERLEVEL10K=true
    echo "--- Starting setup ---"
    echo ""
fi

# ===============================
# Git identity — collected once upfront, used in git config + SSH key
# ===============================
echo "Git identity setup..."
read -p "Enter your Git name: " git_name
read -p "Enter your Git email: " git_email

# ===============================
# 1. Homebrew
# ===============================
echo "[1/17] Setting up Homebrew..."
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    grep -qxF 'eval "$(/opt/homebrew/bin/brew shellenv)"' ~/.zshrc || \
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
brew update

# ===============================
# 2. Core CLI Tools
# ===============================
echo "[2/17] Installing core CLI tools..."
brew install git maven jenv go azure-cli gh

# ===============================
# 3. Git Config + SSH Key
#    Right after git is installed — identity is needed for commits and SSH key
# ===============================
echo "[3/17] Configuring Git..."
git config --global user.name "$git_name"
git config --global user.email "$git_email"
git config --global init.defaultBranch main     # use 'main' instead of 'master'
git config --global pull.rebase false           # merge instead of rebase on pull
git config --global core.editor "nano"          # nano instead of vim

# Global .gitignore — applies to every repo on this machine
echo ".DS_Store\n.env\n*.log\nnode_modules/" > ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global

# SSH Key (optional)
if [[ "$GENERATE_SSH" == true ]]; then
    if [ ! -f ~/.ssh/id_ed25519 ]; then
        echo "Generating SSH key..."
        ssh-keygen -t ed25519 -C "$git_email" -f ~/.ssh/id_ed25519 -N ""
        eval "$(ssh-agent -s)"
        ssh-add ~/.ssh/id_ed25519
        echo ""
        echo "Your public key (add this to GitHub → Settings → SSH Keys):"
        echo "------------------------------------------------------------"
        cat ~/.ssh/id_ed25519.pub
        echo "------------------------------------------------------------"
    else
        echo "SSH key already exists at ~/.ssh/id_ed25519, skipping."
    fi
fi

# ===============================
# 4. nvm + Node + Corepack (pnpm)
# ===============================
echo "[4/17] Installing nvm + Node + pnpm..."
brew install nvm
grep -qxF 'export NVM_DIR="$HOME/.nvm"' ~/.zshrc || \
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
grep -qxF '[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"' ~/.zshrc || \
    echo '[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"' >> ~/.zshrc

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"

nvm install --lts
nvm use --lts

corepack enable
corepack prepare pnpm@8 --activate

# ===============================
# 5. Java + jenv
#    jenv is only configured if Java is being installed
# ===============================
if [[ "$ACTION" == "be" || "$ACTION" == "full" || "$INTERACTIVE" == true ]]; then
    echo "[5/17] Installing Java + jenv..."
    brew install temurin@8 temurin@11 temurin@17 temurin@21 temurin

    grep -qxF 'export PATH="$HOME/.jenv/bin:$PATH"' ~/.zshrc || \
        echo 'export PATH="$HOME/.jenv/bin:$PATH"' >> ~/.zshrc
    grep -qxF 'eval "$(jenv init -)"' ~/.zshrc || \
        echo 'eval "$(jenv init -)"' >> ~/.zshrc
    export PATH="$HOME/.jenv/bin:$PATH"
    eval "$(jenv init -)"

    for jdk in /Library/Java/JavaVirtualMachines/*; do
        if [ -d "$jdk/Contents/Home" ]; then
            jenv add "$jdk/Contents/Home" || true
        fi
    done

    jenv enable-plugin export
    jenv enable-plugin maven
    jenv global 17
else
    echo "[5/17] Skipping Java + jenv (not required for this profile)."
fi

# ===============================
# 6. Apache Tomcat 9 (BE only)
#    Homebrew resolves the latest 9.x version
#    Copied to ~/Documents/tomcat9 for easy access
# ===============================
if [[ "$ACTION" == "be" || "$ACTION" == "full" || "$INTERACTIVE" == true ]]; then
    echo "[6/17] Installing Apache Tomcat 9..."
    brew install tomcat@9

    TOMCAT_DIR="$HOME/Documents/tomcat9"
    if [ ! -d "$TOMCAT_DIR" ]; then
        echo "Copying Tomcat 9 to $TOMCAT_DIR..."
        cp -r /opt/homebrew/opt/tomcat@9/libexec "$TOMCAT_DIR"
        echo "Tomcat 9 installed at: $TOMCAT_DIR"
    else
        echo "Tomcat 9 already exists at $TOMCAT_DIR, skipping."
    fi

    grep -qxF "export CATALINA_HOME=\"$TOMCAT_DIR\"" ~/.zshrc || \
        echo "export CATALINA_HOME=\"$TOMCAT_DIR\"" >> ~/.zshrc
    grep -qxF 'export PATH="$CATALINA_HOME/bin:$PATH"' ~/.zshrc || \
        echo 'export PATH="$CATALINA_HOME/bin:$PATH"' >> ~/.zshrc

    export CATALINA_HOME="$TOMCAT_DIR"
    export PATH="$CATALINA_HOME/bin:$PATH"
    echo "CATALINA_HOME set to: $CATALINA_HOME"
else
    echo "[6/17] Skipping Tomcat (not required for this profile)."
fi

# ===============================
# 7. Applications
#    VS Code + Postman — all profiles
#    Browsers — FE / full / interactive
#    IntelliJ + DBeaver + Rancher — BE / full / interactive
# ===============================
echo "[7/17] Installing applications..."
brew install --cask visual-studio-code postman

if [[ "$ACTION" == "fe" || "$ACTION" == "full" || "$INTERACTIVE" == true ]]; then
    brew install --cask google-chrome firefox
fi

if [[ "$ACTION" == "be" || "$ACTION" == "full" || "$INTERACTIVE" == true ]]; then
    brew install --cask intellij-idea-ce dbeaver-community rancher
fi

# ===============================
# 8. VS Code Extensions
# ===============================
echo "[8/17] Installing VS Code extensions..."
if command -v code &> /dev/null; then
    code --install-extension github.copilot           # AI code completion
    code --install-extension github.copilot-chat      # Copilot chat sidebar
    code --install-extension dbaeumer.vscode-eslint   # ESLint — JS/TS linting
else
    echo "⚠️  VS Code CLI (code) not in PATH."
    echo "   Open VS Code → Cmd+Shift+P → 'Install code command in PATH', then re-run."
fi

# ===============================
# 9. Postman CLI (newman)
# ===============================
echo "[9/17] Installing Postman CLI (newman)..."
npm install -g newman

# ===============================
# 10. Quality of Life Apps
# ===============================
echo "[10/17] Installing quality of life apps..."
brew install --cask rectangle   # window snapping (left/right/quarter layouts)
brew install --cask maccy       # clipboard history (Cmd + Shift + C)
brew install --cask alt-tab     # Windows-style app switcher with previews

# ===============================
# 11. CLI Tools
# ===============================
echo "[11/17] Installing CLI tools..."
brew install bat    # better cat — syntax highlighting for file viewing
brew install wget   # file downloading from terminal
brew install jq     # JSON processor — useful for reading API responses
brew install fzf    # fuzzy finder — search command history and files interactively

# fzf key bindings (Ctrl+R for fuzzy history search, etc.)
$(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc

# ===============================
# 12. macOS System Defaults (optional)
#     Auto-applied for full profile, prompted in interactive mode
# ===============================
if [[ "$CONFIGURE_MACOS" == true ]]; then
    echo "[12/17] Applying macOS settings..."

    # Always show file extensions (.env, .js, .sh etc.)
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true

    # Show full folder path at bottom of Finder windows
    defaults write com.apple.finder ShowPathbar -bool true

    # Faster key repeat — useful when navigating code with arrow keys
    # Lower = faster. macOS default is KeyRepeat=6, InitialKeyRepeat=25
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15

    # Restart Finder to apply changes
    killall Finder

    echo "macOS settings applied."
else
    echo "[12/17] Skipping macOS settings."
fi

# ===============================
# 13. iTerm2 (optional)
# ===============================
if [[ "$INSTALL_ITERM" == true ]]; then
    echo "[13/17] Installing iTerm2..."
    brew install --cask iterm2
else
    echo "[13/17] Skipping iTerm2."
fi

# ===============================
# 14. Oh My Zsh (optional)
# ===============================
if [[ "$INSTALL_OH_MY_ZSH" == true ]]; then
    echo "[14/17] Installing Oh My Zsh..."
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi

    ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        $ZSH_CUSTOM/plugins/zsh-syntax-highlighting || true
    git clone https://github.com/zsh-users/zsh-autosuggestions \
        $ZSH_CUSTOM/plugins/zsh-autosuggestions || true

    sed -i '' 's/^plugins=(.*)/plugins=(git zsh-autosuggestions bgnotify colorize zsh-syntax-highlighting)/' ~/.zshrc || \
        echo 'plugins=(git zsh-autosuggestions bgnotify colorize zsh-syntax-highlighting)' >> ~/.zshrc
else
    echo "[14/17] Skipping Oh My Zsh."
fi

# ===============================
# 15. Nerd Font
#     Installed before Powerlevel10k — required for icons to render correctly
# ===============================
if [[ "$INSTALL_POWERLEVEL10K" == true ]]; then
    echo "[15/17] Installing Nerd Font..."
    brew install --cask font-jetbrains-mono-nerd-font
else
    echo "[15/17] Skipping Nerd Font (Powerlevel10k not selected)."
fi

# ===============================
# 16. SQL Server CLI (sqlcmd) — optional
# ===============================
INSTALL_SQLCMD=false

if [[ "$ACTION" == "full" ]]; then
    INSTALL_SQLCMD=true
elif [[ "$INTERACTIVE" == true ]]; then
    read -p "Install sqlcmd (SQL Server CLI)? (y/n): " answer; [[ "$answer" == "y" ]] && INSTALL_SQLCMD=true
fi

if [[ "$INSTALL_SQLCMD" == true ]]; then
    echo "[16/17] Installing sqlcmd (SQL Server CLI)..."
    brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release
    brew update
    brew install msodbcsql17 mssql-tools
    echo 'export PATH="/usr/local/opt/mssql-tools/bin:$PATH"' >> ~/.zshrc
    export PATH="/usr/local/opt/mssql-tools/bin:$PATH"
else
    echo "[16/17] Skipping sqlcmd installation."
fi

# ===============================
# 17. Powerlevel10k (LAST — takes longest to configure)
# ===============================
if [[ "$INSTALL_POWERLEVEL10K" == true ]]; then
    echo "[17/17] Installing Powerlevel10k..."
    brew install powerlevel10k
    sed -i '' 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' ~/.zshrc || \
        echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> ~/.zshrc
else
    echo "[17/17] Skipping Powerlevel10k."
fi


# ===============================
# Cleanup + Summary
# ===============================
brew cleanup

echo ""
echo "===== Installed Versions ====="
echo "Git  : $(git --version)"
echo "Node : $(node -v 2>/dev/null || echo 'not installed')"
echo "pnpm : $(pnpm -v 2>/dev/null || echo 'not installed')"
echo "Java : $(java -version 2>&1 | head -1 || echo 'not installed')"
echo "Go   : $(go version 2>/dev/null || echo 'not installed')"
echo "nvm  : $(nvm --version 2>/dev/null || echo 'not installed')"
echo ""
echo "===== Setup Completed ====="
echo "Restart your terminal or run: exec \$SHELL"
