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

# 5. Run
docker-compose -f $DEVENV_PATH/docker-compose.yml exec claude-dev bash
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
- Docker CLI & docker-compose
- Agent OS
- Skill_Seekers (with MCP server)
- vim , git, curl, wget

## Docker-in-Docker Support

This container supports running Docker commands to manage containers for your projects. The host's Docker socket is mounted, allowing you to build images, run containers, and use docker-compose from inside the development environment.

**How it works:**
- The container includes Docker CLI and docker-compose plugin
- The host's `/var/run/docker.sock` is mounted into the container
- **Permissions are automatically configured** - works on any system without manual setup
- The entrypoint script detects your host's docker socket GID and configures access dynamically
- Containers you start will run on the host's Docker daemon (sibling containers)

**Usage example:**
```bash
# Inside the container
cd ~/workspace/my-project
docker build -t my-app .
docker run -p 8080:8080 my-app
docker-compose up -d
```

**Cross-platform compatibility:**
The setup works portably across different systems (Linux, macOS, WSL2) without requiring manual configuration. The docker socket permissions are detected and configured automatically at container startup.

**Note:** Containers started from within this environment will be sibling containers running on the host, not nested containers. Volume mounts in those containers should reference host paths, not paths inside this development container.
