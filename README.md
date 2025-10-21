# Claude Code Development Environment

Docker container with Claude Code CLI, Python 3.11, Node.js 20, Agent OS, and Skill_Seekers. Your project files stay on host, tools run in container.

## Setup

```bash
# 1. Clone this repository
git clone <this-repo>
cd claudedevenv
DEVENV_PATH=$(pwd)

# 2. Navigate to your project
cd /path/to/your/project

# 3. Build (one time)
PROJECT_DIR=$(pwd) docker-compose -f $DEVENV_PATH/docker-compose.yml build

# 4. Start container
PROJECT_DIR=$(pwd) docker-compose -f $DEVENV_PATH/docker-compose.yml up -d
```

**Add to your shell config** (`.bashrc`, `.zshrc`, etc.):
```bash
# Replace /path/to/claudedevenv with actual path
export DEVENV_PATH=/path/to/claudedevenv

claude-up() {
    PROJECT_DIR=$(pwd) docker-compose -f $DEVENV_PATH/docker-compose.yml up -d
}

alias claude-compose="docker-compose -f $DEVENV_PATH/docker-compose.yml"
```

Then use:
```bash
cd /path/to/your/project
claude-up          # Starts with current directory mounted
claude-compose down # Stop
```

## Adding Skills via Claude Code

From inside the container, use Claude Code to generate documentation skills with natural language:

```bash
# Inside container
cd ~/workspace
claude
```

Then ask Claude to generate skills:
```
"Generate a React skill from https://react.dev/"
"Create a Tailwind CSS skill from https://tailwindcss.com/docs"
"Generate a Vue skill from https://vuejs.org/guide/"
```

## Agent OS

Spec-driven development system with multi-agent mode. Agent OS is built into the container and **automatically initialized** in your project on first run.

When you start the container for the first time, it will:
- Detect if `agent-os/` exists in your project
- If not, automatically run the setup
- Create `agent-os/` and `.claude/` directories with 15 standards, 4 Claude Code commands, and 13 agents

**Using custom Agent OS profiles (optional):**
If you have a customized agent-os installation on your host:
```bash
export IMPORT_AGENT_OS_PROFILES=/path/to/your/agent-os
claude-up
```

## Data Persistence

| Container Path | Host Path | Purpose |
|---------------|-----------|---------|
| `~/.claude` | `${HOME}/.claude` | Claude config, auth, skills |
| `~/workspace` | Current directory | **Your project files** |
| `~/agent-os` | Built into image | Agent OS base installation |
| `~/skill-seekers` | Built into image | Skill generator tool |

**Always work in `~/workspace`** inside the container to ensure your files persist.

## Installed Tools

- Claude Code 
- Python 3.11.14 (requests, beautifulsoup4, mcp)
- Node.js 
- Agent OS 
- Skill_Seekers (with MCP server)
- vim , git, curl, wget
