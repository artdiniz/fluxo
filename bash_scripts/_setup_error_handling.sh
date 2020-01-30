set -Ee -o pipefail

trap - ERR

_error_handling_ignore_next_warning_var=1

function _err_report {
    if [ $_error_handling_ignore_next_warning_var = 1 ]; then
        printf '%b\n' "Initial Command: $1" "Error at line $2." "Executing: $3"
    else
        _error_handling_ignore_next_warning_var=1
    fi

    return 1
}

function _error_handling_ignore_next_warning {
    _error_handling_ignore_next_warning_var=0

    function _error_handling_reset_warning {
        _error_handling_ignore_next_warning_var=1
        function _error_handling_reset_warning {
            return 1
        }
    }
}

trap '_err_report "$_error_handling_current_command" "$LINENO" "$_error_handling_current_exec"' ERR
