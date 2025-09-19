#!/usr/bin/env bash
# bashrc.sh — One-shot Bash profile installer for Ubuntu/WSL (Mike edition)
# Repo: https://github.com/drake4m/sec-cheat-sheets-n-how-toos
#
# Usage (one-liner once pushed to GitHub):
#   curl -fsSL https://raw.githubusercontent.com/drake4m/sec-cheat-sheets-n-how-toos/main/bashrc.sh | bash
#
# Options:
#   curl -fsSL ... | bash -s -- [--no-packages] [--minimal] [--no-starship] [--force] [--no-reload]
#
# Behavior:
#   • Updates apt metadata, installs packages (unless --no-packages).
#   • Installs Starship prompt (unless --no-starship).
#   • Backs up existing ~/.bashrc and writes a new one (unless --force to skip prompt).
#   • Reloads shell (unless --no-reload).

set -euo pipefail

# -------- Args --------
NO_PKGS=0
FORCE=0
NO_RELOAD=0
MINIMAL=0
NO_STARSHIP=0

for arg in "${@:-}"; do
  case "$arg" in
    --no-packages) NO_PKGS=1 ;;
    --force)       FORCE=1 ;;
    --no-reload)   NO_RELOAD=1 ;;
    --minimal)     MINIMAL=1 ;;
    --no-starship) NO_STARSHIP=1 ;;
    *)
      echo "Unknown option: $arg" >&2
      echo "Supported: --no-packages --minimal --no-starship --force --no-reload" >&2
      exit 2
      ;;
  esac
done

# -------- Sanity --------
if ! command -v bash >/dev/null 2>&1; then
  echo "[!] bash not found." >&2
  exit 1
fi

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if ! command -v sudo >/dev/null 2>&1; then
    echo "[!] sudo not available. Run as root or install sudo." >&2
    exit 1
  fi
  SUDO="sudo"
fi

# -------- Detect Ubuntu-ish (warn only) --------
if [ -r /etc/os-release ]; then
  . /etc/os-release
  case "${ID_LIKE:-$ID}" in
    *ubuntu*|*debian*) : ;;
    *) echo "[i] Non-Ubuntu detected (${ID:-unknown}). Proceeding anyway." ;;
  esac
fi

# -------- Packages --------
if [ "$MINIMAL" -eq 1 ]; then
  # Bare essentials to make profile work
  PKGS=(bash-completion git)
else
  # Full toolset
  PKGS=(
    bash-completion
    git ripgrep fd-find fzf bat eza tree
    jq delta direnv
    python3-venv python3-pip
    fonts-powerline
  )
fi

if [ "$NO_PKGS" -eq 0 ]; then
  echo "[*] Updating apt metadata…"
  $SUDO DEBIAN_FRONTEND=noninteractive apt-get update -y

  echo "[*] Installing packages: ${PKGS[*]}"
  for p in "${PKGS[@]}"; do
    if ! dpkg -s "$p" >/dev/null 2>&1; then
      if ! $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y "$p"; then
        echo "[!] Package '$p' not available. Skipping."
      fi
    fi
  done
else
  echo "[i] Skipping apt installs (--no-packages)."
fi

# -------- Starship prompt (optional, default ON) --------
if [ "$NO_STARSHIP" -eq 0 ]; then
  if ! command -v starship >/dev/null 2>&1; then
    echo "[*] Installing Starship prompt…"
    # starship installer respects -y to avoid prompts
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y || echo "[!] Failed to install starship (continuing)."
  else
    echo "[i] Starship already installed."
  fi
else
  echo "[i] Skipping Starship install (--no-starship)."
fi

# -------- Write ~/.bashrc (backup first) --------
TARGET="$HOME/.bashrc"
if [ -f "$TARGET" ] && [ "$FORCE" -ne 1 ]; then
  BKP="$HOME/.bashrc.bak.$(date +%Y%m%d%H%M%S)"
  cp "$TARGET" "$BKP"
  echo "[*] Backed up existing ~/.bashrc to: $BKP"
fi

echo "[*] Installing new ~/.bashrc"
# shellcheck disable=SC2016
cat > "$TARGET" <<"EOF_BASHRC"
# ~/.bashrc — Mike's enhanced Bash for Ubuntu/WSL

# --- Exit if not interactive ---
case $- in
    *i*) ;;
      *) return;;
esac

# --- History configuration ---
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=5000
HISTFILESIZE=10000
HISTTIMEFORMAT="%F %T "

# --- Check window size automatically ---
shopt -s checkwinsize

# --- Lesspipe for friendly preview ---
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# --- Chroot indicator for prompt ---
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# --- Color support detection ---
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    color_prompt=yes
else
    color_prompt=
fi

# --- Prompt: user@host:full/path with optional git branch ---
if [ "$color_prompt" = yes ]; then
    if command -v __git_ps1 >/dev/null 2>&1; then
        PS1='${debian_chroot:+($debian_chroot)}\[\033[0;32m\]\u@\h\[\033[00m\]:\[\033[0;34m\]\w\[\033[0;33m\]$(__git_ps1 " (%s)")\[\033[00m\]\n\$ '
    else
        PS1='${debian_chroot:+($debian_chroot)}\[\033[0;32m\]\u@\h\[\033[00m\]:\[\033[0;34m\]\w\[\033[00m\]\n\$ '
    fi
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi

# --- Window title (xterm/Windows Terminal) ---
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
esac

# --- LS colors / dircolors ---
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# Prefer modern 'eza' else fallback to 'ls'
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first --git'
    alias ll='eza -lh --group-directories-first --git'
    alias la='eza -lha --group-directories-first --git'
    alias lt='eza -lh --tree --level=2'
else
    alias ls='ls --color=auto'
    alias ll='ls -alF --color=auto'
    alias la='ls -A --color=auto'
    alias l='ls -CF --color=auto'
fi

# bat/batcat wrapper
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
elif command -v batcat >/dev/null 2>&1; then
    alias bat='batcat'
    alias cat='batcat --paging=never'
fi

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Load personal aliases if present
[ -f ~/.bash_aliases ] && . ~/.bash_aliases

# Enable bash-completion
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Git completions (if installed)
[ -f /usr/share/bash-completion/completions/git ] && source /usr/share/bash-completion/completions/git

# fzf integration (if installed)
if command -v fzf >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*" 2>/dev/null || fd --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    [ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && source /usr/share/doc/fzf/examples/key-bindings.bash
    [ -f /usr/share/doc/fzf/examples/completion.bash ]   && source /usr/share/doc/fzf/examples/completion.bash
fi

# QoL aliases
alias ..='cd ..'
alias ...='cd ../..'
alias please='sudo $(fc -ln -1)'
alias dfh='df -hT'
alias duh='du -h -d 1 2>/dev/null'
alias ports='ss -tulpen'

# Safer defaults
stty -ixon 2>/dev/null || true
shopt -s globstar extglob

# WSL niceties (noop on non-WSL)
export WSL_NO_GLOBAL_PATH=1 2>/dev/null || true

# --- Optional: Starship prompt (if installed) ---
# To use Starship, ensure it's installed and uncomment the next line:
# eval "$(starship init bash)"
EOF_BASHRC

# -------- If starship installed & not opted out, enable it in ~/.bashrc --------
if [ "$NO_STARSHIP" -eq 0 ] && command -v starship >/dev/null 2>&1; then
  if ! grep -q 'starship init bash' "$HOME/.bashrc"; then
    echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
    echo "[*] Enabled Starship prompt in ~/.bashrc"
  else
    echo "[i] Starship already enabled in ~/.bashrc"
  fi
fi

# -------- Reload shell --------
if [ "$NO_RELOAD" -eq 0 ]; then
  echo "[*] Reloading shell…"
  if [[ $- == *i* ]]; then
    # shellcheck disable=SC1090
    source "$HOME/.bashrc"
  else
    exec bash -l
  fi
else
  echo "[i] Skipped reload (--no-reload). Run: source ~/.bashrc"
fi

echo "[✓] Done."
