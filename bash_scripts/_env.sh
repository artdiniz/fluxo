#!/usr/bin/env bash

# Future reference to improve symlinked script path resolution:
#     https://stackoverflow.com/questions/29832037/how-to-get-script-directory-in-posix-sh/29835459#29835459

_FLUXO_COMMAND_NAME="$(basename "$0")"
_FLUXO_COMMAND="$_FLUXO_COMMAND_NAME $@"

if [ -L "$BASH_SOURCE" ]; then
	_SCRIPT_DIR="$(ls -l "$BASH_SOURCE" | sed 's/^.* -> \(.*\)$/\1/')"
else
	_SCRIPT_DIR="$BASH_SOURCE"
fi

_FLUXO_SCRIPTS_DIR="$( cd "$( dirname "$_SCRIPT_DIR" )" >/dev/null 2>&1 && pwd )"

_error_handling_current_command="$_FLUXO_COMMAND"
. "$_FLUXO_SCRIPTS_DIR/_setup_error_handling.sh"
. "$_FLUXO_SCRIPTS_DIR/_setup_lib_run.sh"
. "$_FLUXO_SCRIPTS_DIR/_setup_help.sh"