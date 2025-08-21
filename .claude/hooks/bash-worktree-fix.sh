#!/bin/sh
# POSIX-compliant Claude pre-tool-use hook for Bash tool
# Automatically prepends worktree path to Bash commands when in a worktree

# Configuration
DEBUG_MODE="${CLAUDE_HOOK_DEBUG:-false}"

# Debug logging (POSIX compliant)
debug_log() {
    case "${DEBUG_MODE:-}" in
        true|TRUE|1|yes|YES)
            echo "DEBUG [bash-worktree-fix]: $*" >&2
            ;;
    esac
}

# Detect if we're in a worktree and get its path
get_worktree_path() {
    check_dir="$(pwd)"
    
    while [ "${check_dir}" != "/" ]; do
        if [ -f "${check_dir}/.git" ]; then
            # Found potential worktree or submodule marker
            # Read only the first line; suppress errors if unreadable
            if IFS= read -r gitdir_content 2>/dev/null < "${check_dir}/.git"; then
                :
            else
                gitdir_content=""
            fi
            
            # Check if it's a worktree (not a submodule)
            case "${gitdir_content}" in
                gitdir:*worktrees/*)
                    # This is a true worktree
                    debug_log "Found worktree at: ${check_dir}"
                    echo "${check_dir}"
                    return 0
                    ;;
                gitdir:*)
                    # This is a submodule, not a worktree
                    debug_log "Found submodule (not worktree) at: ${check_dir}"
                    return 1
                    ;;
                *)
                    # Unknown format
                    debug_log "Unknown .git file format at: ${check_dir}"
                    return 1
                    ;;
            esac
        elif [ -d "${check_dir}/.git" ]; then
            # Regular git repo, not a worktree
            debug_log "Found regular repo at: ${check_dir}"
            return 1
        fi
        check_dir="$(dirname "${check_dir}")"
    done
    
    debug_log "No git repository found"
    return 1
}

# Check if command should be skipped
should_skip_command() {
    cmd="$1"
    
    # Tokenize to get the first word (avoid pathname expansion)
    old_flags="$-"
    set -f
    set -- $cmd
    first="$1"
    case "${old_flags}" in *f*) ;; *) set +f ;; esac
    
    # Skip if command already starts with cd
    if [ "${first}" = "cd" ]; then
        debug_log "Skipping: command already has cd"
        return 0
    fi
    
    # Skip certain built-in commands that don't need directory context
    case "${first}" in
        pwd|echo|export|alias|source|.)
            debug_log "Skipping: matches skip pattern"
            return 0
            ;;
        /*)
            # Check if first token is absolute path
            debug_log "Skipping: command uses absolute path"
            return 0
            ;;
        *)
            # Process this command
            ;;
    esac
    
    return 1
}

# Safely quote a path for shell execution
shell_quote() {
    # Produce a safely single-quoted path
    # Escape any single quotes in the path
    printf "%s" "$1" | sed "s/'/'\\\\''/g"
}

# Inject the worktree prefix
inject_prefix() {
    worktree_path="$1"
    command="$2"
    
    # Produce a safely quoted path
    qpath="$(shell_quote "${worktree_path}")"
    
    # Trim trailing spaces and detect backgrounding
    trimmed="${command}"
    while [ "${trimmed% }" != "${trimmed}" ]; do
        trimmed="${trimmed% }"
    done
    
    case "${trimmed}" in
        *"&")
            # Remove the & suffix, add prefix with quoted path, then restore it
            cmd_without_bg="${trimmed%&}"
            # Trim any trailing spaces after removing &
            while [ "${cmd_without_bg% }" != "${cmd_without_bg}" ]; do
                cmd_without_bg="${cmd_without_bg% }"
            done
            echo "cd '${qpath}' && ${cmd_without_bg} &"
            ;;
        *)
            # Normal command with quoted path
            echo "cd '${qpath}' && ${command}"
            ;;
    esac
}

# Main execution
main() {
    # Capture all arguments as the command
    original_command="$*"
    
    debug_log "Processing command: ${original_command}"
    
    # Check if we're in a worktree
    if worktree_path="$(get_worktree_path)"; then
        # We're in a worktree
        
        # Check if we should skip this command
        if should_skip_command "${original_command}"; then
            debug_log "Passing through unchanged"
            echo "${original_command}"
        else
            # Inject the prefix
            modified_command="$(inject_prefix "${worktree_path}" "${original_command}")"
            debug_log "Modified command: ${modified_command}"
            echo "${modified_command}"
        fi
    else
        # Not in a worktree, pass through unchanged
        debug_log "Not in worktree, passing through unchanged"
        echo "${original_command}"
    fi
}

# Execute main function with all arguments
main "$@"
