#!/usr/bin/env bash
set -eE -o pipefail

trap - ERR
trap - EXIT

_error_handling_ignore_next_warning_var=1
_has_already_run=1

function _err_report {
    local _command="$1"
    local _stack_top_command="$2"
    local _line_number="$3"
    local _status_code="$4"
    if [ $_error_handling_ignore_next_warning_var = 1 ] && [ $_status_code -gt 0 ] && [ $_has_already_run -eq 1 ]; then
        printf '\n'
        printf "$(tput setab 1)$(tput setaf 7)$(tput bold) %s $(tput sgr0) in '%s' \n status code %s at %s:%s\\n\\n" \
            "Unexpected Error" "$_command" "$_status_code" "$_stack_top_command" "$_line_number"
    elif [ $_error_handling_ignore_next_warning_var = 0 ]; then
        _error_handling_ignore_next_warning_var=1
    fi

    _has_already_run=0
    exit $_status_code
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

trap '_err_report "$0 $@" "$_error_handling_current_exec" $LINENO $?' ERR
trap '_err_report "$0 $@" "$_error_handling_current_exec" $LINENO $?' EXIT
