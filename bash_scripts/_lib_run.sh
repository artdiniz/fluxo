. "$_FLUXO_SCRIPTS_DIR/lib_grep.sh"
. "$_FLUXO_SCRIPTS_DIR/lib_util.sh"
. "$_FLUXO_SCRIPTS_DIR/lib_get_branches.sh"
. "$_FLUXO_SCRIPTS_DIR/lib_view.sh"
. "$_FLUXO_SCRIPTS_DIR/lib_navigate_to_git_repository_root.sh"
. "$_FLUXO_SCRIPTS_DIR/lib_read_fluxo_file.sh"
. "$_FLUXO_SCRIPTS_DIR/lib_style.sh"

function _lib_run {
    _old_error_handling_current_exec="$_error_handling_current_exec"
    _old__error_handling_ignore_next_warning_var="$_error_handling_ignore_next_warning_var"
    
    _error_handling_current_exec="function $1"
    _error_handling_ignore_next_warning_var=1
    # . "$_FLUXO_SCRIPTS_DIR/_error_handling.sh"

    local status_code=0

    "$@" || status_code=$?

    _error_handling_current_exec="$_old_error_handling_current_exec"
    _error_handling_ignore_next_warning_var="$_old__error_handling_ignore_next_warning_var"
    # . "$_FLUXO_SCRIPTS_DIR/_error_handling.sh"

    return $status_code
}