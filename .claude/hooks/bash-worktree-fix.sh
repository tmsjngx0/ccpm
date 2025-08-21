#!/bin/sh
# POSIX-compliant pre-tool-use hook for Bash tool
# Goal: If inside a Git *worktree checkout*, prefix the incoming command with:
#       cd '<worktree_root>' && <original_command>
# WITHOUT changing execution semantics (no extra sh -c), no tokenization,
# no broken quoting, and with robust worktree detection.

DEBUG_MODE="${CLAUDE_HOOK_DEBUG:-false}"

debug_log() {
    case "${DEBUG_MODE:-}" in
        true|TRUE|1|yes|YES)
            printf '%s\n' "DEBUG [bash-worktree-fix]: $*" >&2
            ;;
    esac
}

# Safely single-quote a string for shell usage
shell_squote() {
    printf "%s" "$1" | sed "s/'/'\"'\"'/g"
}

# Detect if CWD is inside a *linked worktree* and print the worktree root
get_worktree_path() {
    check_dir="$(pwd)"

    if [ ! -d "${check_dir}" ]; then
        debug_log "pwd is not a directory: ${check_dir}"
        return 1
    fi

    while [ "${check_dir}" != "/" ]; do
        if [ -f "${check_dir}/.git" ]; then
            gitdir_content=""
            if [ -r "${check_dir}/.git" ]; then
                IFS= read -r gitdir_content < "${check_dir}/.git" || gitdir_content=""
            else
                debug_log "Unreadable .git file at: ${check_dir}"
            fi

            case "${gitdir_content}" in
                gitdir:*)
                    gitdir_path=${gitdir_content#gitdir:}
                    while [ "${gitdir_path# }" != "${gitdir_path}" ]; do
                        gitdir_path=${gitdir_path# }
                    done
                    case "${gitdir_path}" in
                        /*) abs_gitdir="${gitdir_path}" ;;
                        *)  abs_gitdir="${check_dir}/${gitdir_path}" ;;
                    esac
                    if [ -d "${abs_gitdir}" ]; then
                        case "${abs_gitdir}" in
                            */worktrees/*)
                                debug_log "Detected worktree root: ${check_dir} (gitdir: ${abs_gitdir})"
                                printf '%s\n' "${check_dir}"
                                return 0
                                ;;
                            *)
                                debug_log "Non-worktree .git indirection at: ${check_dir}"
                                return 1
                                ;;
                        esac
                    else
                        debug_log "gitdir path does not exist: ${abs_gitdir}"
                        return 1
                    fi
                    ;;
                *)
                    debug_log "Unknown .git file format at: ${check_dir}"
                    return 1
                    ;;
            esac
        elif [ -d "${check_dir}/.git" ]; then
            debug_log "Found regular git repo at: ${check_dir}"
            return 1
        fi

        check_dir=$(dirname -- "${check_dir}")
    done

    debug_log "No git repository found"
    return 1
}

# Decide whether to skip prefixing
should_skip_command() {
    cmd=$1

    # Empty or whitespace-only?
    if [ -z "${cmd##*[! 	]*}" ]; then
        # Note: literal space and tab between [! 	]
        debug_log "Skipping: empty/whitespace-only command"
        return 0
    fi

    _oldset="$-"
    set -f

    # Starts with cd?
    case "${cmd}" in
        [ 	]cd|cd|[ 	]cd[ 	]*|cd[ 	]*)
            case "${_oldset}" in *f*) : ;; *) set +f ;; esac
            debug_log "Skipping: command already begins with cd"
            return 0
            ;;
    esac

    # Builtins safe to skip
    case "${cmd}" in
        :|[ 	]:|true|[ 	]true|false|[ 	]false|\
        pwd|[ 	]pwd*|echo|[ 	]echo*|\
        export|[ 	]export*|alias|[ 	]alias*|\
        unalias|[ 	]unalias*|set|[ 	]set*|\
        unset|[ 	]unset*|readonly|[ 	]readonly*|\
        umask|[ 	]umask*|times|[ 	]times*|\
        .|[ 	].[ 	]*)
            case "${_oldset}" in *f*) : ;; *) set +f ;; esac
            debug_log "Skipping: trivial/builtin command"
            return 0
            ;;
    esac

    # Absolute path
    case "${cmd}" in
        /*|[ 	]/*)
            case "${_oldset}" in *f*) : ;; *) set +f ;; esac
            debug_log "Skipping: absolute path command"
            return 0
            ;;
    esac

    case "${_oldset}" in *f*) : ;; *) set +f ;; esac
    return 1
}

# Inject prefix
inject_prefix() {
    worktree_path=$1
    command=$2

    qpath=$(shell_squote "${worktree_path}")

    trimmed=${command}
    while [ "${trimmed% }" != "${trimmed}" ]; do
        trimmed=${trimmed% }
    done

    case "${trimmed}" in
        *"&")
            cmd_without_bg=${trimmed%&}
            while [ "${cmd_without_bg% }" != "${cmd_without_bg}" ]; do
                cmd_without_bg=${cmd_without_bg% }
            done
            printf '%s\n' "cd '${qpath}' && ${cmd_without_bg} &"
            ;;
        *)
            printf '%s\n' "cd '${qpath}' && ${command}"
            ;;
    esac
}

main() {
    original_command=$*

    debug_log "Processing command: ${original_command}"

    if worktree_path="$(get_worktree_path)"; then
        if should_skip_command "${original_command}"; then
            debug_log "Passing through unchanged"
            printf '%s\n' "${original_command}"
        else
            modified_command="$(inject_prefix "${worktree_path}" "${original_command}")"
            debug_log "Modified command: ${modified_command}"
            printf '%s\n' "${modified_command}"
        fi
    else
        debug_log "Not in worktree, passing through unchanged"
        printf '%s\n' "${original_command}"
    fi
}

main "$@"
