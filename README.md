# Environment Setup Script

Automate env setup for Debian/Ubuntu.
Installing my popular tools and some control over stuff

---

## Features

- **Prerequisite Checks**: Ensures the script is run as root and has an internet connection.
- **Iranian Repositories**: Configures APT repositories for faster package downloads in Iran.
- **DNS Setup**: Configures DNS servers for better connectivity.
- **Package Installation**: Installs essential packages.
- **Optional Installations**:
    - Visual Studio Code
    - Google Chrome
    - Docker
    - Go (Golang)
- **Configuration Files**: Downloads and applies custom configuration files.
- **Argument Support**: Allows skipping specific installations using command-line flags.

---

## Prerequisites

- **Operating System**: Ubuntu or Debian-based Linux distributions.
- **Permissions**: The script must be run as root (use `sudo`).
- **Internet Connection**: Required for downloading packages and repositories.

---

## Usage

1. **Download the Script**:
   ```bash
   wget https://example.com/path/to/setup_script.sh
   chmod +x setup_script.sh
   ```

2. **Run the Script**:
   ```bash
   sudo ./setup_script.sh [OPTIONS]
   ```

### Command-Line Options

| Option          | Description                                      |
|-----------------|--------------------------------------------------|
| `--no-dns`      | Skip DNS configuration.                          |
| `--no-golang`   | Skip Go (Golang) installation.                   |
| `--no-docker`   | Skip Docker installation.                        |
| `--no-vscode`   | Skip Visual Studio Code installation.            |
| `--no-chrome`   | Skip Google Chrome installation.                 |

### Examples

- **Run the script with all features**:
  ```bash
  sudo ./setup_script.sh
  ```

- **Skip DNS and Docker installation**:
  ```bash
  sudo ./setup_script.sh --no-dns --no-docker
  ```

- **Skip Chrome and Go installation**:
  ```bash
  sudo ./setup_script.sh --no-chrome --no-golang
  ```

---

## What the Script Installs

### Packages
- `apt-transport-https`
- `ca-certificates`
- `lsb-release`
- `xclip`
- `python3`
- `python3-pip`
- `vim`
- `zsh`
- `tmux`
- `kitty`
- `tor`
- `git`
- `wget`
- `fzf`
- `autojump`

### Tools
- **Visual Studio Code**: A code editor.
- **Google Chrome**: A web browser.
- **Docker**: A platform for containerized applications.
- **Go (Golang)**: A programming language.
- **Warp Plus**: A CLI tool for enhanced connectivity.

### Configuration Files
- `.zshrc`: Configuration for Zsh.
- `.tmux.conf`: Configuration for Tmux.
- `kitty.conf`: Configuration for Kitty terminal.

---

## Customization

You can customize the script by modifying the following variables:

- **Repositories**: Edit the `set_iranian_repos` function to change the mirror URLs.
- **DNS Servers**: Modify the `dns_servers` array in the `setup_dns` function.
- **Packages**: Add or remove packages from the `packages` array.
