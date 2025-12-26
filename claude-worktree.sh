#!/bin/bash
set -e

# Claude Code Worktree Launcher
# This script helps launch multiple Claude Code instances in different git worktrees

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect which docker compose command to use
detect_docker_compose() {
    if docker compose version &>/dev/null; then
        echo "docker compose"
    elif docker-compose --version &>/dev/null; then
        echo "docker-compose"
    else
        echo "Error: Neither 'docker compose' nor 'docker-compose' is available" >&2
        exit 1
    fi
}

DOCKER_COMPOSE=$(detect_docker_compose)

show_usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] <command> [worktree-path]

Commands:
    up <path>       Start Claude Code instance in the specified worktree
    down <path>     Stop Claude Code instance in the specified worktree
    rebuild <path>  Rebuild and restart Claude Code instance
    attach <path>   Attach to running Claude Code instance
    logs <path>     Show logs from Claude Code instance
    list            List all running Claude Code instances
    ps              Alias for list

Options:
    -h, --help      Show this help message

Examples:
    # Start Claude Code in a worktree
    $(basename "$0") up /path/to/worktree

    # Rebuild and restart an instance
    $(basename "$0") rebuild /path/to/worktree

    # Attach to the running instance
    $(basename "$0") attach /path/to/worktree

    # Stop the instance
    $(basename "$0") down /path/to/worktree

    # List all running instances
    $(basename "$0") list

Notes:
    - Each worktree gets its own isolated container
    - Container names are based on the worktree directory name
    - All instances share the same ~/.claude configuration
    - Docker socket is mounted for nested Docker operations
EOF
}

# Generate a project name from a path
get_project_name() {
    local path="$1"
    local abs_path=$(cd "$path" 2>/dev/null && pwd || echo "$path")
    local dir_name=$(basename "$abs_path")
    # Sanitize: replace non-alphanumeric chars with hyphens, convert to lowercase
    echo "claude-${dir_name}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g'
}

# Detect if a path is a git worktree and return the git common directory
# Returns empty string if not a worktree or not a git repo
get_git_common_dir() {
    local path="$1"
    local abs_path=$(cd "$path" 2>/dev/null && pwd || echo "$path")

    # Check if this is a git worktree (has .git file, not directory)
    if [ -f "$abs_path/.git" ]; then
        # This is a worktree - get the git common directory
        local git_common_dir=$(cd "$abs_path" && git rev-parse --git-common-dir 2>/dev/null)
        if [ -n "$git_common_dir" ]; then
            # Convert to absolute path
            echo $(cd "$abs_path" && cd "$git_common_dir" && pwd)
        fi
    fi
}

# Start a Claude Code instance
cmd_up() {
    local worktree_path="$1"

    if [ -z "$worktree_path" ]; then
        echo "Error: Worktree path is required"
        echo "Usage: $(basename "$0") up <worktree-path>"
        exit 1
    fi

    if [ ! -d "$worktree_path" ]; then
        echo "Error: Directory does not exist: $worktree_path"
        exit 1
    fi

    local abs_path=$(cd "$worktree_path" && pwd)
    local project_name=$(get_project_name "$abs_path")
    local container_name="${project_name}-dev"
    local git_common_dir=$(get_git_common_dir "$abs_path")

    echo "Starting Claude Code instance:"
    echo "  Worktree: $abs_path"
    echo "  Project:  $project_name"
    echo "  Container: $container_name"
    if [ -n "$git_common_dir" ]; then
        echo "  Git common dir: $git_common_dir (worktree detected)"
    fi
    echo

    cd "$SCRIPT_DIR"

    # Build compose command with optional worktree support
    local compose_files="-f docker-compose.yml"
    if [ -n "$git_common_dir" ]; then
        compose_files="$compose_files -f docker-compose.worktree.yml"
    fi

    PROJECT_DIR="$abs_path" \
    CONTAINER_NAME="$container_name" \
    COMPOSE_PROJECT_NAME="$project_name" \
    GIT_COMMON_DIR="${git_common_dir:-}" \
    $DOCKER_COMPOSE $compose_files up -d

    echo
    echo "Claude Code is starting..."
    echo "To attach to the container, run:"
    echo "  $(basename "$0") attach \"$worktree_path\""
    echo "Or manually:"
    echo "  docker exec -it $container_name bash"
}

# Stop a Claude Code instance
cmd_down() {
    local worktree_path="$1"

    if [ -z "$worktree_path" ]; then
        echo "Error: Worktree path is required"
        echo "Usage: $(basename "$0") down <worktree-path>"
        exit 1
    fi

    local abs_path=$(cd "$worktree_path" 2>/dev/null && pwd || echo "$worktree_path")
    local project_name=$(get_project_name "$abs_path")

    echo "Stopping Claude Code instance for project: $project_name"

    cd "$SCRIPT_DIR"
    COMPOSE_PROJECT_NAME="$project_name" \
    $DOCKER_COMPOSE down

    echo "Instance stopped."
}

# Rebuild a Claude Code instance
cmd_rebuild() {
    local worktree_path="$1"

    if [ -z "$worktree_path" ]; then
        echo "Error: Worktree path is required"
        echo "Usage: $(basename "$0") rebuild <worktree-path>"
        exit 1
    fi

    if [ ! -d "$worktree_path" ]; then
        echo "Error: Directory does not exist: $worktree_path"
        exit 1
    fi

    local abs_path=$(cd "$worktree_path" && pwd)
    local project_name=$(get_project_name "$abs_path")
    local container_name="${project_name}-dev"
    local git_common_dir=$(get_git_common_dir "$abs_path")

    echo "Rebuilding Claude Code instance:"
    echo "  Worktree: $abs_path"
    echo "  Project:  $project_name"
    echo "  Container: $container_name"
    if [ -n "$git_common_dir" ]; then
        echo "  Git common dir: $git_common_dir (worktree detected)"
    fi
    echo

    cd "$SCRIPT_DIR"

    # Build compose command with optional worktree support
    local compose_files="-f docker-compose.yml"
    if [ -n "$git_common_dir" ]; then
        compose_files="$compose_files -f docker-compose.worktree.yml"
    fi

    echo "Stopping existing instance..."
    COMPOSE_PROJECT_NAME="$project_name" \
    $DOCKER_COMPOSE $compose_files down

    echo
    echo "Rebuilding and starting..."
    PROJECT_DIR="$abs_path" \
    CONTAINER_NAME="$container_name" \
    COMPOSE_PROJECT_NAME="$project_name" \
    GIT_COMMON_DIR="${git_common_dir:-}" \
    $DOCKER_COMPOSE $compose_files up -d --build

    echo
    echo "Claude Code has been rebuilt and is starting..."
    echo "To attach to the container, run:"
    echo "  $(basename "$0") attach \"$worktree_path\""
    echo "Or manually:"
    echo "  docker exec -it $container_name bash"
}

# Attach to a running instance
cmd_attach() {
    local worktree_path="$1"

    if [ -z "$worktree_path" ]; then
        echo "Error: Worktree path is required"
        echo "Usage: $(basename "$0") attach <worktree-path>"
        exit 1
    fi

    local abs_path=$(cd "$worktree_path" 2>/dev/null && pwd || echo "$worktree_path")
    local project_name=$(get_project_name "$abs_path")
    local container_name="${project_name}-dev"

    echo "Attaching to container: $container_name"
    docker exec -it -u developer "$container_name" bash
}

# Show logs
cmd_logs() {
    local worktree_path="$1"

    if [ -z "$worktree_path" ]; then
        echo "Error: Worktree path is required"
        echo "Usage: $(basename "$0") logs <worktree-path>"
        exit 1
    fi

    local abs_path=$(cd "$worktree_path" 2>/dev/null && pwd || echo "$worktree_path")
    local project_name=$(get_project_name "$abs_path")

    cd "$SCRIPT_DIR"
    COMPOSE_PROJECT_NAME="$project_name" \
    $DOCKER_COMPOSE logs -f
}

# List all running Claude Code instances
cmd_list() {
    echo "Running Claude Code instances:"
    echo
    docker ps --filter "name=claude-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -1
    docker ps --filter "name=claude-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "claude-" || echo "No running instances found."
}

# Main command dispatcher
main() {
    if [ $# -eq 0 ]; then
        show_usage
        exit 0
    fi

    case "$1" in
        -h|--help)
            show_usage
            exit 0
            ;;
        up)
            shift
            cmd_up "$@"
            ;;
        down)
            shift
            cmd_down "$@"
            ;;
        rebuild)
            shift
            cmd_rebuild "$@"
            ;;
        attach)
            shift
            cmd_attach "$@"
            ;;
        logs)
            shift
            cmd_logs "$@"
            ;;
        list|ps)
            cmd_list
            ;;
        *)
            echo "Error: Unknown command '$1'"
            echo
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
