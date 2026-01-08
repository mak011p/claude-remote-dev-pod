#!/bin/bash
set -e

echo "Starting dev-pod entrypoint..."

# Setup SSH authorized keys from mounted secret
if [ -f /etc/ssh-keys/authorized_keys ]; then
    echo "Setting up SSH authorized keys..."
    mkdir -p /home/dev/.ssh
    cp /etc/ssh-keys/authorized_keys /home/dev/.ssh/authorized_keys
    chmod 700 /home/dev/.ssh
    chmod 600 /home/dev/.ssh/authorized_keys
    chown -R dev:dev /home/dev/.ssh
fi

# Setup Claude Code hooks if mounted
if [ -f /etc/claude-hooks/settings.json ]; then
    echo "Setting up Claude Code settings..."
    mkdir -p /home/dev/.claude
    cp /etc/claude-hooks/settings.json /home/dev/.claude/settings.json
    chown -R dev:dev /home/dev/.claude
fi

if [ -f /etc/claude-hooks/notify-hook.sh ]; then
    echo "Setting up Claude Code notification hook..."
    mkdir -p /home/dev/.claude/hooks
    cp /etc/claude-hooks/notify-hook.sh /home/dev/.claude/hooks/notify-hook.sh
    chmod +x /home/dev/.claude/hooks/notify-hook.sh
    chown -R dev:dev /home/dev/.claude
fi

# Create default .bashrc if not exists (PVC might be empty on first run)
if [ ! -f /home/dev/.bashrc ]; then
    echo "Creating default .bashrc..."
    cat > /home/dev/.bashrc << 'EOF'
# Default bashrc for dev-pod

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend

# Check window size after each command
shopt -s checkwinsize

# Prompt
PS1='\[\033[01;32m\]\u@dev-pod\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias gs='git status'
alias gd='git diff'
alias gc='git commit'
alias gp='git push'

# Enable color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi

# Claude Code environment
export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"

# Auto-attach to tmux if not already in a session
if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
    tmux attach-session -t main 2>/dev/null || tmux new-session -s main
fi
EOF
    chown dev:dev /home/dev/.bashrc
fi

# Create default .tmux.conf if not exists
if [ ! -f /home/dev/.tmux.conf ]; then
    echo "Creating default .tmux.conf..."
    cat > /home/dev/.tmux.conf << 'EOF'
# Enable mouse support
set -g mouse on

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows when one is closed
set -g renumber-windows on

# Increase history limit
set -g history-limit 50000

# Enable 256 colors
set -g default-terminal "screen-256color"

# Status bar
set -g status-style 'bg=#333333 fg=#5eacd3'
set -g status-left '#[fg=green]#S '
set -g status-right '#[fg=yellow]%Y-%m-%d %H:%M'

# Easy reload config
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Split panes using | and -
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Switch panes with Alt+arrow
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D
EOF
    chown dev:dev /home/dev/.tmux.conf
fi

# Ensure home directory ownership
chown -R dev:dev /home/dev

echo "Entrypoint setup complete. Starting SSH server..."

# Execute the main command
exec "$@"
