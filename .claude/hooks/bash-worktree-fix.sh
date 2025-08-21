#!/bin/bash
# Advanced Claude pre-tool-use hook for Bash tool
# Handles complex scenarios and edge cases

# Configuration
DEBUG_MODE="${CLAUDE_HOOK_DEBUG:-false}"
SKIP_COMMANDS_REGEX="^(pwd|echo|export|alias|source|\.)"

# Debug logging
debug_log() {
    if [ "$DEBUG_MODE" = "true" ]; then
        echo "DEBUG [bash-worktree-fix]: $*" >&2
    fi
}

# Detect if we're in a worktree and get its path
get_worktree_path() {
    local check_dir="$(pwd)"
    
    while [ "$check_dir" != "/" ]; do
        if [ -f "$check_dir/.git" ]; then
            # Found worktree marker
            local gitdir_content="$(cat "$check_dir/.git")"
            
            # Validate it's actually a worktree file
            if [[ "$gitdir_content" =~ ^gitdir: ]]; then
                debug_log "Found worktree at: $check_dir"
                echo "$check_dir"
                return 0
            fi
        elif [ -d "$check_dir/.git" ]; then
            # Regular git repo, not a worktree
            debug_log "Found regular repo at: $check_dir"
            return 1
        fi
        check_dir="$(dirname "$check_dir")"
    done
    
    debug_log "No git repository found"
    return 1
}

# Check if command should be skipped
should_skip_command() {
    local cmd="$1"
    
    # Skip if command already has cd at the start
    if [[ "$cmd" =~ ^cd[[:space:]] ]]; then
        debug_log "Skipping: command already has cd"
        return 0
    fi
    
    # Skip certain commands that don't need directory context
    if [[ "$cmd" =~ $SKIP_COMMANDS_REGEX ]]; then
        debug_log "Skipping: matches skip pattern"
        return 0
    fi
    
    # Skip if command is changing to an absolute path anyway
    if [[ "$cmd" =~ ^[[:space:]]*/[^[:space:]]+ ]]; then
        debug_log "Skipping: command uses absolute path"
        return 0
    fi
    
    return 1
}

# Inject the worktree prefix
inject_prefix() {
    local worktree_path="$1"
    local command="$2"
    
    # Handle complex command structures
    case "$command" in
        # Background commands
        *" &"*)
            # Split at the & and inject before it
            local cmd_part="${command% &*}"
            local bg_part="${command#"$cmd_part"}"
            echo "cd $worktree_path && $cmd_part$bg_part"
            ;;
        
        # Piped commands - inject only at the start
        *"|"*)
            echo "cd $worktree_path && $command"
            ;;
        
        # Environment variable setting
        *"="*" "*)
            # Check if it's VAR=value command format
            if [[ "$command" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
                # Split environment vars from command
                local env_part="${command%% *}"
                local cmd_part="${command#* }"
                echo "cd $worktree_path && $env_part $cmd_part"
            else
                echo "cd $worktree_path && $command"
            fi
            ;;
        
        # Default case
        *)
            echo "cd $worktree_path && $command"
            ;;
    esac
}

# Main execution
main() {
    local original_command="$1"
    
    debug_log "Processing command: $original_command"
    
    # Check if we're in a worktree
    if worktree_path=$(get_worktree_path); then
        # We're in a worktree
        
        # Check if we should skip this command
        if should_skip_command "$original_command"; then
            debug_log "Passing through unchanged"
            echo "$original_command"
        else
            # Inject the prefix
            local modified_command=$(inject_prefix "$worktree_path" "$original_command")
            debug_log "Modified command: $modified_command"
            echo "$modified_command"
        fi
    else
        # Not in a worktree, pass through unchanged
        debug_log "Not in worktree, passing through unchanged"
        echo "$original_command"
    fi
}

# Execute main function with all arguments
main "$@"
