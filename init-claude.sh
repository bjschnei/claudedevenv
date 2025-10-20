#!/bin/bash
set -e

# Initialize .claude directory structure if needed
if [ ! -f ~/.claude/.initialized ]; then
    mkdir -p ~/.claude/{debug,skills,commands,agents}
    touch ~/.claude/.initialized
fi

# Initialize agent-os if mounted directory is empty
if [ -d ~/agent-os ] && [ ! "$(ls -A ~/agent-os)" ]; then
    if [ -d ~/.agent-os-template ]; then
        cp -r ~/.agent-os-template/* ~/agent-os/
        echo "Agent OS initialized from template"
    fi
fi

# Run agent-os project setup if needed
if [ -d ~/agent-os ] && [ ! -f ~/agent-os/.initialized ]; then
    if [ -f ~/agent-os/scripts/project-install.sh ]; then
        bash ~/agent-os/scripts/project-install.sh --multi-agent-mode 2>/dev/null || true
    fi
    touch ~/agent-os/.initialized
fi

echo "Environment ready"
exec bash