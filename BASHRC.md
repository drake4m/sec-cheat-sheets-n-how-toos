# Bash RC: One-Shot Installer (Ubuntu / WSL)

Opinionated, practical Bash profile for Ubuntu/WSL with:

- **Classic prompt**: `user@host:/full/path (git-branch)` in color
- **Completions**: system + Git, optional fzf
- **Tooling**: `ripgrep`, `fd-find`, `fzf`, `bat`, `eza`, `jq`, `tree`, `delta`, `direnv`, Python venv/pip
- **Starship prompt** (enabled by default)
- Sensible history, QoL aliases, and colorized output

---

## Quick install (one-liner)

```bash
curl -fsSL https://raw.githubusercontent.com/drake4m/sec-cheat-sheets-n-how-toos/main/bashrc.sh | bash
# Skip apt installs (just apply ~/.bashrc)
curl -fsSL https://raw.githubusercontent.com/drake4m/sec-cheat-sheets-n-how-toos/main/bashrc.sh | bash -s -- --no-packages

# Minimal package set (bash-completion, git only)
curl -fsSL https://raw.githubusercontent.com/drake4m/sec-cheat-sheets-n-how-toos/main/bashrc.sh | bash -s -- --minimal

# Skip Starship installation
curl -fsSL https://raw.githubusercontent.com/drake4m/sec-cheat-sheets-n-how-toos/main/bashrc.sh | bash -s -- --no-starship

# Overwrite without backup prompt + don't reload shell
curl -fsSL https://raw.githubusercontent.com/drake4m/sec-cheat-sheets-n-how-toos/main/bashrc.sh | bash -s -- --force --no-reload

What it installs

By default (no flags), the script runs:

sudo apt-get update then installs:

bash-completion
git ripgrep fd-find fzf bat eza tree
jq delta direnv
python3-venv python3-pip
fonts-powerline


Starship prompt (via official installer), and enables it in ~/.bashrc.

It then backs up your previous ~/.bashrc to ~/.bashrc.bak.<timestamp> and writes a new one.

If some packages aren’t available on your Ubuntu release, the installer skips them gracefully.

Prompt behavior

Default: classic user@host:/full/path prompt with colors.

Shows (branch) when inside a Git repo.

If Starship is installed (default), the installer appends:

eval "$(starship init bash)"


You can comment this line in ~/.bashrc to return to the classic PS1.

Useful aliases & enhancements

ls → eza (with git info) if present, else ls --color

cat → bat/batcat if present

.., ..., please (sudo rerun of last command), dfh, duh, ports

fzf integration auto-enables if fzf is installed

Verify integrity (optional)
tmp=/tmp/bashrc.sh
url="https://raw.githubusercontent.com/drake4m/sec-cheat-sheets-n-how-toos/main/bashrc.sh"
curl -fsSL "$url" -o "$tmp"
# Replace <SHA256> with a published digest after you push
echo "<SHA256>  $tmp" | sha256sum -c -
bash "$tmp"


Generate a SHA256:

sha256sum bashrc.sh

Uninstall / revert

Restore your backup:

cp ~/.bashrc.bak.<timestamp> ~/.bashrc
source ~/.bashrc


To remove Starship (optional):

sudo rm -f /usr/local/bin/starship
# or if installed to ~/.cargo/bin:
rm -f ~/.cargo/bin/starship

Notes

Designed for Ubuntu/WSL; works on most Debian-like systems.

Uses apt-get with noninteractive flags; safe to run repeatedly.

On older Ubuntu LTS, some packages may be missing (script skips and continues).

WSL-specific setting WSL_NO_GLOBAL_PATH is harmless on non-WSL.

MIT © drake4m


---
