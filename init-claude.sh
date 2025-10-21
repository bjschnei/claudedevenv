#!/bin/bash
set -e

# Initialize .claude directory structure if needed
if [ ! -f ~/.claude/.initialized ]; then
    mkdir -p ~/.claude/{debug,skills,commands,agents}
    touch ~/.claude/.initialized
fi

# Check if project needs agent-os initialization
if [ ! -d ~/workspace/agent-os ]; then
    if [ -f ~/agent-os/scripts/project-install.sh ]; then
        echo "Initializing Agent OS in project..."
        cd ~/workspace
        bash ~/agent-os/scripts/project-install.sh --multi-agent-mode 2>/dev/null || true
        echo "Agent OS initialized"
    fi
fi

# Optionally import custom profiles from host's agent-os if IMPORT_AGENT_OS_PROFILES is set
# This allows users to bring their own customized agent-os profiles
# To use: export IMPORT_AGENT_OS_PROFILES=/path/to/your/agent-os before running claude-up
if [ -n "$IMPORT_AGENT_OS_PROFILES" ] && [ -d "$IMPORT_AGENT_OS_PROFILES" ]; then
    if [ -d ~/workspace/agent-os ]; then
        echo "Importing custom Agent OS profiles from host..."
        # Copy custom profiles, preserving existing files
        cp -rn "$IMPORT_AGENT_OS_PROFILES"/* ~/workspace/agent-os/ 2>/dev/null || true
        echo "Custom profiles imported"
    fi
fi

echo "Environment ready"
exec bash