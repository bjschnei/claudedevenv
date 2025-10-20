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

# 5. Access container
docker-compose -f $DEVENV_PATH/docker-compose.yml exec claude-dev bash

# 6. (Optional) Authenticate Claude Code
claude login
```

**Add to your shell config** (`.bashrc`, `.zshrc`, etc.) to make it permanent:
```bash
# Replace /path/to/claudedevenv with actual path
export DEVENV_PATH=/path/to/claudedevenv

# Function to start claude-compose with current directory
claude-up() {
    PROJECT_DIR=$(pwd) docker-compose -f $DEVENV_PATH/docker-compose.yml up -d
}

# Alias for other commands
alias claude-compose="docker-compose -f $DEVENV_PATH/docker-compose.yml"
```

Then use:
```bash
cd /path/to/your/project
claude-up          # Starts with current directory mounted
claude-compose exec claude-dev bash
```

## Usage

### Basic Commands

```bash
cd /path/to/your/project
claude-up                               # Start (mounts current directory)
claude-compose down                     # Stop
claude-compose exec claude-dev bash     # Enter container
claude-compose logs                     # View logs
claude-compose restart                  # Restart (preserves mounts)
```

### Working with Files

Edit files on your host with any editor. Changes appear instantly in the container at `~/workspace`.

```bash
# Inside container
cd ~/workspace
python3 app.py
claude "add docstrings and type hints"
```

## Creating Claude Skills with Skill_Seekers

Skill_Seekers scrapes documentation sites and converts them into Claude skills.

### Example: Create React Skill

```bash
# Inside container
cd ~/workspace

# Option 1: Use pre-configured React config
python3 ~/skill-seekers/cli/doc_scraper.py --config ~/skill-seekers/configs/react.json

# Option 2: Interactive mode for custom documentation
python3 ~/skill-seekers/cli/doc_scraper.py --interactive
# Enter URL: https://react.dev/reference/react
# Enter name: react
# Follow prompts...

# Output is saved to: ~/workspace/output/react/

# Install the skill (persists to host)
cp -r output/react ~/.claude/skills/react
```

### Example: Create Vue.js Skill

```bash
cd ~/workspace

# Create custom config
cat > vue-config.json << EOF
{
    "name": "vue",
    "base_url": "https://vuejs.org/guide/",
    "max_pages": 500,
    "follow_links": true
}
EOF

# Generate skill
python3 ~/skill-seekers/cli/doc_scraper.py --config vue-config.json

# Install skill
cp -r output/vue ~/.claude/skills/vue
```

### Available Pre-configured Skills

Located in `~/skill-seekers/configs/`:
- `react.json` - React documentation
- `vue.json` - Vue.js documentation
- `django.json` - Django web framework
- `fastapi.json` - FastAPI framework
- `tailwind.json` - Tailwind CSS
- `kubernetes.json` - Kubernetes documentation
- `godot.json` - Godot game engine
- `astro.json` - Astro web framework

### Custom Skill Configuration

Create a JSON config file:

```json
{
    "name": "my-framework",
    "base_url": "https://docs.example.com",
    "max_pages": 1000,
    "follow_links": true,
    "depth_limit": 3,
    "exclude_patterns": ["blog", "tutorial"]
}
```

Then run:
```bash
python3 ~/skill-seekers/cli/doc_scraper.py --config my-config.json
```

### Advanced: MCP Integration (Optional)

**For Claude Code desktop app users only.** This allows you to generate skills using natural language commands.

The MCP (Model Context Protocol) server is pre-installed and provides tools like `generate_config`, `scrape_docs`, `package_skill`, etc.

**Setup on your host machine:**

```bash
# 1. Create MCP config directory (on host)
mkdir -p ~/.config/claude-code

# 2. Add Skill_Seekers MCP server to config
# Edit ~/.config/claude-code/mcp.json and add:
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

# 3. Restart Claude Code desktop app
```

**Usage in Claude Code:**
```
"List all available configs"
"Generate a React skill from https://react.dev/"
"Validate configs/react.json"
```

For more details, see `~/skill-seekers/README.md` and `~/skill-seekers/QUICK_MCP_TEST.md` inside the container.

## Agent OS

Spec-driven development system with multi-agent mode.

### Install in Project

```bash
cd ~/workspace/my-project
~/agent-os/scripts/project-install.sh
```

Creates `agent-os/` and `.claude/` directories in your project with:
- 15 standards (backend, frontend, global, testing)
- 4 Claude Code commands (new-spec, create-spec, implement-spec, plan-product)
- 13 agents (api-engineer, database-engineer, ui-designer, etc.)

### Customize Base Templates

```bash
vim ~/agent-os/profiles/default/standards/global/tech-stack.md
```

Changes persist to `${HOME}/agent-os` on your host.

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

## Troubleshooting

### Build Issues

First build takes 5-10 minutes. Retry if network timeouts occur.

### Container Won't Start

```bash
claude-compose logs
```

### Wrong Directory Mounted (Shows devenv files instead of project)

This happens if `PROJECT_DIR` wasn't set when starting the container.

**Fix:**
```bash
claude-compose down
cd /path/to/your/project
claude-up
```

Or manually:
```bash
cd /path/to/your/project
PROJECT_DIR=$(pwd) claude-compose up -d
```

**Verify correct directory:**
```bash
claude-compose exec claude-dev ls /home/developer/workspace
# Should show YOUR project files, not devenv files
```

### Permission Errors

Ensure Docker has access to:
- Your project directory
- `~/.claude`
- `~/agent-os`

### Rebuild from Scratch

```bash
cd /path/to/your/project
claude-compose down
PROJECT_DIR=$(pwd) claude-compose build --no-cache
PROJECT_DIR=$(pwd) claude-compose up -d
```

Or using the function:
```bash
cd /path/to/your/project
claude-compose down
claude-up
```

## Advanced Configuration

### Expose Ports for Web Development

Edit `/path/to/claudedevenv/docker-compose.yml`:

```yaml
services:
  claude-dev:
    ports:
      - "3000:3000"
      - "8000:8000"
```

### Container Architecture

```
/home/developer/
├── .claude/              # Mounted from ${HOME}/.claude
├── agent-os/            # Mounted from ${HOME}/agent-os
├── workspace/           # Mounted from current directory
└── skill-seekers/       # Built into image
```

## Testing

```bash
./test/test.sh
```

Validates: build, container startup, tools, volume mounts, persistence.
