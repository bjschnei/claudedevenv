#!/bin/bash
set -e

# Handle Docker socket permissions dynamically (works on any system)
if [ -S /var/run/docker.sock ]; then
    DOCKER_SOCK_GID=$(stat -c '%g' /var/run/docker.sock 2>/dev/null || stat -f '%g' /var/run/docker.sock 2>/dev/null)

    if [ -n "$DOCKER_SOCK_GID" ]; then
        # Check if a group with this GID already exists
        if ! getent group "$DOCKER_SOCK_GID" >/dev/null 2>&1; then
            # Create docker group with the correct GID
            groupadd -g "$DOCKER_SOCK_GID" docker
        fi

        # Add developer user to the docker group
        usermod -aG "$DOCKER_SOCK_GID" developer 2>/dev/null || true
    fi
fi

# Switch to developer user for remaining setup
exec su - developer -c '
set -e

# Initialize .claude directory structure if needed
if [ ! -f ~/.claude/.initialized ]; then
    mkdir -p ~/.claude/{debug,skills,commands,agents}
    touch ~/.claude/.initialized
fi

# Install command templates from container to workspace
if [ -d ~/templates/commands ]; then
    mkdir -p ~/workspace/.claude/commands
    # Copy templates, but don'\''t overwrite existing commands
    for cmd_file in ~/templates/commands/*.md; do
        if [ -f "$cmd_file" ]; then
            cmd_name=$(basename "$cmd_file")
            if [ ! -f ~/workspace/.claude/commands/"$cmd_name" ]; then
                echo "Installing command: $cmd_name"
                cp "$cmd_file" ~/workspace/.claude/commands/
            fi
        fi
    done
fi

# Check if project needs agent-os initialization
if [ ! -d ~/workspace/agent-os ]; then
    if [ -f ~/agent-os/scripts/project-install.sh ]; then
        echo "Initializing Agent OS in project..."
        cd ~/workspace
        bash ~/agent-os/scripts/project-install.sh 2>/dev/null || true
        echo "Agent OS initialized"
    fi
fi

# Optionally import custom profiles from host'\''s agent-os if IMPORT_AGENT_OS_PROFILES is set
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

# Setup Skill Seekers MCP integration if not already configured
if [ -f ~/skill-seekers/setup_mcp.sh ] && [ ! -f ~/.claude-mcp-configured ]; then
    echo "Setting up Skill Seekers MCP integration..."
    cd ~/skill-seekers
    bash setup_mcp.sh 2>/dev/null || echo "Warning: Skill Seekers MCP setup encountered issues"
    touch ~/.claude-mcp-configured
    echo "Skill Seekers MCP integration configured"
fi

# Note: If .mcp.json contains Docker MCP Gateway config from host, it will
# show as "failed" in /mcp (expected - Docker MCP Gateway runs on host only).
# The in-container Playwright MCP configured below will work correctly.

# Setup Playwright MCP if not already configured
if [ ! -f ~/.claude-playwright-mcp-configured ]; then
    echo "Setting up Playwright MCP..."
    cd ~/workspace
    claude mcp add playwright -- npx @playwright/mcp@latest --browser chromium --headless --no-sandbox --isolated 2>/dev/null || echo "Warning: Playwright MCP setup encountered issues"
    touch ~/.claude-playwright-mcp-configured
    echo "Playwright MCP configured"
fi

echo "Environment ready"
exec bash
'