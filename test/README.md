# Test Suite

Comprehensive tests for Claude Code Docker Environment.

## Running Tests

```bash
./test/test.sh
```

## What Gets Tested

- Docker image build
- Container startup and health
- Directory structure initialization
- Tool versions (Claude Code, Python, Node.js)
- Python dependencies (requests, beautifulsoup4, mcp)
- MCP package installation and imports
- Skill_Seekers CLI functionality
- Skill_Seekers config files (12+ configs)
- MCP server startup
- Fresh environment setup
- Existing directory preservation
- Volume mount persistence

## Test Files

- `test.sh` - Main test script
- `docker-compose.test.yml` - Test-specific compose configuration

## Test Artifacts

Tests create temporary directories that are automatically cleaned up:
- `test-fresh/` - Fresh environment test
- `test-home/` - Existing directory preservation test

These are excluded in `.gitignore`.
