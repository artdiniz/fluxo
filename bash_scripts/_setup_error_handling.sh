#!/usr/bin/env bash
set -eE -o pipefail

trap - ERR
trap - EXIT

_error_handling_ignore_next_warning_var=1
_has_already_run=1

function _err_report {
    local _source_file="$1"
    local _command="$(basename "$2")"
    local _commmand_args="$3"
    local _stack_top_command="$4"
    local _line_number="$5"
    local _status_code="$6"

    local _error_tag="$(tput setab 1)$(tput setaf 7)$(tput bold) Unexpected Error $(tput sgr0)"
    local _error_tag_space="                  "

    if [ $_error_handling_ignore_next_warning_var = 1 ] && [ $_status_code -gt 0 ] && [ $_has_already_run -eq 1 ]; then
        printf '\n'
        printf "$_error_tag Command    : %s \n$_error_tag_space Source file: %s \n$_error_tag_space Exit code  : %s \n$_error_tag_space Stack top  : %s:%s\\n\\n" \
            "$_command $_commmand_args" "$_source_file" "$_status_code" "$_stack_top_command" "$_line_number"
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

trap '_err_report "$0" "$_COMMAND_META_COMMAND" "$_COMMAND_META_ARGS" "$_error_handling_current_exec" $LINENO $?' ERR
trap '_err_report "$0" "$_COMMAND_META_COMMAND" "$_COMMAND_META_ARGS" "$_error_handling_current_exec" $LINENO $?' EXIT
