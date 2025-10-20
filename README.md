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

## Adding Skills via Claude Code (MCP)

Skill_Seekers is integrated with Claude Code through MCP, allowing you to generate documentation skills using natural language.

### MCP Setup

1. **Create MCP config directory** (on your host):
```bash
mkdir -p ~/.config/claude-code
```

2. **Add Skill_Seekers MCP server** to `~/.config/claude-code/mcp.json`:
```json
{
  "mcpServers": {
    "skill-seeker": {
      "command": "docker",
      "args": [
        "compose",
        "-f", "/path/to/claudedevenv/docker-compose.yml",
        "exec",
        "-T",
        "claude-dev",
        "python3",
        "/home/developer/skill-seekers/mcp/server.py"
      ]
    }
  }
}
```

3. **Restart Claude Code**

### Using Skills in Claude Code

Ask Claude Code in natural language:

```
"List all available configs"
"Generate a React skill from https://react.dev/"
"Create a Tailwind CSS skill from https://tailwindcss.com/docs"
"Scrape docs using configs/vue.json"
```

### Available Pre-configured Skills

Located in the container at `~/skill-seekers/configs/`:
- react, vue, django, fastapi
- tailwind, kubernetes, godot, astro

## Agent OS

Spec-driven development system with multi-agent mode.

**Install in your project:**
```bash
# Inside container
cd ~/workspace/my-project
~/agent-os/scripts/project-install.sh
```

Creates `agent-os/` and `.claude/` directories with 15 standards, 4 Claude Code commands, and 13 agents.

## Data Persistence

| Container Path | Host Path | Purpose |
|---------------|-----------|---------|
| `~/.claude` | `${HOME}/.claude` | Claude config, auth, skills |
| `~/agent-os` | `${HOME}/agent-os` | Agent OS base installation |
| `~/workspace` | Current directory | **Your project files** |
| `~/skill-seekers` | Built into image | Skill generator tool |

**Always work in `~/workspace`** inside the container to ensure your files persist.

## Installed Tools

- Claude Code 2.0.22
- Python 3.11.14 (requests, beautifulsoup4, mcp)
- Node.js 20.11.1
- Agent OS 2.0.5
- Skill_Seekers (with MCP server)
- vim 9.0, git, curl, wget
