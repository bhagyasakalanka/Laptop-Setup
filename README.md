# 💻 Laptop-Setup

Just got a new laptop? Use **Laptop-Setup** to install and configure your development environment like a pro in one go! Supports multiple profiles or interactive mode to choose what gets installed.

---

## 🚀 Overview

This script automates the setup of a developer laptop:

* Installs essential development tools
* Configures Git and SSH
* Sets up programming languages
* Installs applications
* Optionally configures terminal enhancements and macOS defaults

---

## ⬇️ Installation

Download the setup script to your laptop:

```bash
curl -O https://raw.githubusercontent.com/bhagyasakalanka/Laptop-Setup/main/setup-mac.sh
chmod +x setup-mac.sh
```

---

## 🎯 Profiles

| Profile       | Description                                             |
| ------------- | ------------------------------------------------------- |
| `fe`          | Frontend developer setup (iTerm2, Oh My Zsh, browsers)  |
| `be`          | Backend developer setup (Java, Tomcat, IDEs, CLI tools) |
| `basic`       | Minimal tools only                                      |
| `full`        | Everything + macOS defaults                             |
| `interactive` | No profile, prompts you for each option                 |

**Usage Examples:**

```bash
# Full setup
./setup.sh -a full

# Frontend setup only
./setup.sh -a fe

# Interactive mode
./setup.sh
```

---

## ✨ Key Features

1. **Homebrew**

   * Installs Homebrew if missing and updates it

2. **Core CLI Tools**

   * git, maven, jenv, go, azure-cli, GitHub CLI (`gh`)

3. **Git Configuration**

   * Sets global username, email, default branch (`main`), rebase behavior, editor (`nano`)
   * Sets global `.gitignore` with `.DS_Store`, `.env`, `*.log`, `node_modules/`

4. **SSH Key** (optional)

   * Generates an `ed25519` SSH key for GitHub

5. **Node.js, npm, pnpm**

   * Installs `nvm`, Node LTS version, enables `corepack` and `pnpm`

6. **Java + jenv** (backend/full/interactive)

   * Installs multiple Temurin JDKs (8, 11, 17, 21)
   * Configures `jenv` with export and maven plugins
   * Sets default Java version to 17

7. **Apache Tomcat 9** (backend/full/interactive)

   * Installs Tomcat 9 via Homebrew
   * Copies to `~/Documents/tomcat9`
   * Sets `CATALINA_HOME` and adds to PATH

8. **Applications**

   * VS Code, Postman (all profiles)
   * Chrome, Firefox (frontend/full/interactive)
   * IntelliJ, DBeaver, Rancher (backend/full/interactive)

9. **VS Code Extensions**

   * GitHub Copilot, Copilot Chat, ESLint

10. **Postman CLI (`newman`)**

    * Installs globally via npm

11. **Quality of Life Apps**

    * Rectangle (window snapping), Maccy (clipboard history), Alt-Tab (app switcher)

12. **CLI Utilities**

    * bat, wget, jq, fzf
    * Installs fzf key bindings

13. **macOS Defaults** (full/interactive, optional)

    * Show file extensions
    * Show full folder path in Finder
    * Faster key repeat
    * Applies changes by restarting Finder

14. **iTerm2** (optional)

15. **Oh My Zsh** (optional)

    * Installs Oh My Zsh, plugins: autosuggestions, syntax highlighting

16. **Nerd Font** (required for Powerlevel10k) (optional)

17. **SQL Server CLI (`sqlcmd`)** (optional)

18. **Powerlevel10k** (optional)

    * Installs and configures theme in `.zshrc`

---

## ⚙️ Requirements

* macOS 11 or higher
* Internet connection
* Terminal access for installation

---

## ✅ After Setup

Restart your terminal or run:

```bash
exec $SHELL
```

Verify installed tools:

```bash
git --version
node -v
pnpm -v
java -version
go version
nvm --version
```

---

## 🤝 Contributing

Contributions are welcome! Fork, improve, add features, or extend support to other OSes.

---
