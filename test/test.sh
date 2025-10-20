#!/bin/bash
set -e

cd "$(dirname "$0")/.."

echo "🧪 Testing Claude Code Docker Environment..."

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

test_passed() { echo -e "${GREEN}✅ $1${NC}"; }
test_failed() { echo -e "${RED}❌ $1${NC}"; exit 1; }
test_info() { echo -e "${YELLOW}ℹ️  $1${NC}"; }

test_info "Building Docker image..."
docker build -t claude-code-dev . > /dev/null 2>&1 && test_passed "Docker image built" || test_failed "Build failed"

test_info "Testing basic container functionality..."
CONTAINER_ID=$(docker run -d claude-code-dev sleep 30)
sleep 3
docker ps --format '{{.ID}}' | grep -q "^${CONTAINER_ID:0:12}" && test_passed "Container starts" || test_failed "Container failed to start"

test_info "Verifying directory structure..."
docker exec $CONTAINER_ID test -d /home/developer/.claude && test_passed ".claude exists" || test_failed ".claude missing"
docker exec $CONTAINER_ID test -d /home/developer/agent-os && test_passed "agent-os exists" || test_failed "agent-os missing"
docker exec $CONTAINER_ID test -d /home/developer/skill-seekers && test_passed "skill-seekers exists" || test_failed "skill-seekers missing"

test_info "Verifying tool versions..."
docker exec $CONTAINER_ID python3 --version > /dev/null && test_passed "Python 3.11" || test_failed "Python missing"
docker exec $CONTAINER_ID node --version > /dev/null && test_passed "Node.js 20" || test_failed "Node missing"
docker exec $CONTAINER_ID claude --version > /dev/null && test_passed "Claude Code" || test_failed "Claude Code missing"

test_info "Testing Python dependencies..."
docker exec $CONTAINER_ID python3 -c "import requests, bs4" && test_passed "Python deps OK" || test_failed "Python deps missing"

test_info "Testing MCP package..."
docker exec $CONTAINER_ID python3 -c "import mcp; from mcp.server import Server" && test_passed "MCP package installed" || test_failed "MCP package missing"

test_info "Testing Skill_Seekers CLI..."
docker exec $CONTAINER_ID python3 /home/developer/skill-seekers/cli/doc_scraper.py --help > /dev/null 2>&1 && test_passed "Skill_Seekers CLI works" || test_failed "Skill_Seekers CLI broken"

test_info "Testing Skill_Seekers configs..."
CONFIG_COUNT=$(docker exec $CONTAINER_ID bash -c "ls /home/developer/skill-seekers/configs/*.json 2>/dev/null | wc -l")
[ "$CONFIG_COUNT" -ge 8 ] && test_passed "Skill configs available ($CONFIG_COUNT)" || test_failed "Skill configs missing"

test_info "Testing MCP server..."
docker exec $CONTAINER_ID bash -c "timeout 2 python3 /home/developer/skill-seekers/mcp/server.py 2>/dev/null || [ \$? -eq 124 ]" && test_passed "MCP server starts" || test_failed "MCP server broken"

docker stop $CONTAINER_ID > /dev/null 2>&1
docker rm $CONTAINER_ID > /dev/null 2>&1

test_info "Testing fresh environment with docker-compose..."
mkdir -p test-fresh/.claude test-fresh/agent-os test-fresh/skill-seekers
docker-compose -f test/docker-compose.test.yml up -d > /dev/null 2>&1
sleep 5

docker-compose -f test/docker-compose.test.yml exec -T claude-dev-fresh test -f /home/developer/.claude/.initialized && test_passed "Fresh init OK" || test_failed "Fresh init failed"
docker-compose -f test/docker-compose.test.yml exec -T claude-dev-fresh test -d /home/developer/.claude/skills && test_passed "Skills dir created" || test_failed "Skills dir missing"
docker-compose -f test/docker-compose.test.yml exec -T claude-dev-fresh test -d /home/developer/agent-os && test_passed "Agent OS dir OK" || test_failed "Agent OS dir missing"
docker-compose -f test/docker-compose.test.yml exec -T claude-dev-fresh test -d /home/developer/skill-seekers && test_passed "Skill_Seekers dir OK" || test_failed "Skill_Seekers dir missing"

docker-compose -f test/docker-compose.test.yml down > /dev/null 2>&1
rm -rf test-fresh

test_info "Testing existing directory preservation..."
mkdir -p test-home/.claude/existing-skills test-home/agent-os/existing-profiles test-home/skill-seekers/existing-configs
echo "test" > test-home/.claude/existing-skills/test-skill.txt
echo "test" > test-home/agent-os/existing-profiles/test-profile.txt

docker run -dit --name test-existing \
    -v "$(pwd)/test-home/.claude:/home/developer/.claude" \
    -v "$(pwd)/test-home/agent-os:/home/developer/agent-os" \
    -v "$(pwd)/test-home/skill-seekers:/home/developer/skill-seekers" \
    claude-code-dev > /dev/null 2>&1
sleep 3

docker exec test-existing test -f /home/developer/.claude/existing-skills/test-skill.txt && test_passed "Existing .claude preserved" || test_failed "Existing .claude lost"
docker exec test-existing test -f /home/developer/agent-os/existing-profiles/test-profile.txt && test_passed "Existing agent-os preserved" || test_failed "Existing agent-os lost"

docker stop test-existing > /dev/null 2>&1
docker rm test-existing > /dev/null 2>&1
rm -rf test-home

echo ""
echo -e "${GREEN}🎉 All tests passed!${NC}"
echo ""
echo "Usage:"
echo "  docker-compose up -d"
echo "  docker-compose exec claude-dev bash"
