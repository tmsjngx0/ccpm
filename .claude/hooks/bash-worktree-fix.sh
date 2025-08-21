#!/bin/sh
# POSIX-compliant Claude pre-tool-use hook for Bash tool
# Automatically prepends worktree path to Bash commands when in a worktree

# Configuration
DEBUG_MODE="${CLAUDE_HOOK_DEBUG:-false}"

# Debug logging (POSIX compliant)
debug_log() {
    if [ "$DEBUG_MODE" = "true" ]; then
        echo "DEBUG [bash-worktree-fix]: $*" >&2
    fi
}

# Detect if we're in a worktree and get its path
get_worktree_path() {
    check_dir="$(pwd)"
    
    while [ "$check_dir" != "/" ]; do
        if [ -f "$check_dir/.git" ]; then
            # Found potential worktree marker
            gitdir_content="$(cat "$check_dir/.git" 2>/dev/null || true)"
            
            # Check if it starts with "gitdir:"
            case "$gitdir_content" in
                gitdir:*)
                    debug_log "Found worktree at: $check_dir"
                    echo "$check_dir"
                    return 0
                    ;;
            esac
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
    cmd="$1"
    
    # Skip if command already has cd at the start
    case "$cmd" in
        cd\ *|cd${TAB}*)
            debug_log "Skipping: command already has cd"
            return 0
            ;;
    esac
    
    # Skip certain commands that don't need directory context
    case "$cmd" in
        pwd*|echo*|export*|alias*|source*|.*)
            debug_log "Skipping: matches skip pattern"
            return 0
            ;;
    esac
    
    # Skip if command starts with absolute path
    case "$cmd" in
        /*)
            debug_log "Skipping: command uses absolute path"
            return 0
            ;;
    esac
    
    return 1
}

# Inject the worktree prefix
inject_prefix() {
    worktree_path="$1"
    command="$2"
    
    # Handle background commands - check if ends with " &"
    case "$command" in
        *" &")
            # Remove the " &" suffix, add prefix, then restore it
            cmd_without_bg="${command% &}"
            echo "cd $worktree_path && $cmd_without_bg &"
            ;;
        *" &"*)
            # Has & but not at the end - just prefix normally
            echo "cd $worktree_path && $command"
            ;;
        *)
            # Normal command
            echo "cd $worktree_path && $command"
            ;;
    esac
}

# Main execution
main() {
    original_command="$1"
    
    debug_log "Processing command: $original_command"
    
    # Check if we're in a worktree
    if worktree_path="$(get_worktree_path)"; then
        # We're in a worktree
        
        # Check if we should skip this command
        if should_skip_command "$original_command"; then
            debug_log "Passing through unchanged"
            echo "$original_command"
        else
            # Inject the prefix
            modified_command="$(inject_prefix "$worktree_path" "$original_command")"
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
