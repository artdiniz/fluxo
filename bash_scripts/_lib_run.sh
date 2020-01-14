. $(cd "$(dirname "$0")" && pwd)"/lib_grep.sh"
. $(cd "$(dirname "$0")" && pwd)"/lib_util.sh"
. $(cd "$(dirname "$0")" && pwd)"/lib_get_branches.sh"
. $(cd "$(dirname "$0")" && pwd)"/lib_view.sh"
. $(cd "$(dirname "$0")" && pwd)"/lib_navigate_to_git_repository_root.sh"
. $(cd "$(dirname "$0")" && pwd)"/lib_read_fluxo_file.sh"
. $(cd "$(dirname "$0")" && pwd)"/lib_style.sh"

function _lib_run {
    _old_error_handling_current_exec="$_error_handling_current_exec"
    _old__error_handling_ignore_next_warning_var="$_error_handling_ignore_next_warning_var"
    
    _error_handling_current_exec="function $1"
    _error_handling_ignore_next_warning_var=1
    # . $(cd "$(dirname "$0")" && pwd)"/_error_handling.sh"

    local status_code=0

    "$@" || status_code=$?

    _error_handling_current_exec="$_old_error_handling_current_exec"
    _error_handling_ignore_next_warning_var="$_old__error_handling_ignore_next_warning_var"
    # . $(cd "$(dirname "$0")" && pwd)"/_error_handling.sh"

    return $status_code
}