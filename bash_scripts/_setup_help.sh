function _create_string_var {
	local _message_var_name
	_message_var_name="$1"

	IFS= read -d '' -r $_message_var_name
}

function _help_print_full_message {
	local _message

	local _usage_view _options_view _params_view _other_view

	[ "$_HELP_USAGE" ] && _create_string_var _usage_view <<-TITLE
		$(tput bold)USAGE$(tput sgr0)
		
		$_HELP_USAGE
	TITLE

	[ "$_HELP_OPTIONS" ] && _create_string_var _options_view <<-TITLE
		$(tput bold)OPTIONS$(tput sgr0)
		
		$_HELP_OPTIONS
	TITLE

	[ "$_HELP_PARAMS" ] && _create_string_var _params_view <<-TITLE
		$(tput bold)PARAMS$(tput sgr0)
		
		$_HELP_PARAMS
	TITLE

	[ "$_HELP_OTHER" ] && _create_string_var _other_view <<-TITLE
		$(tput bold)===$(tput sgr0)
		
		$_HELP_OTHER
	TITLE

	# $_FLUXO_COMMAND_NAME diff -h | --help
    # --help                                       show detailed instructions

	local _help_view="$(_lib_run view_join "$_usage_view" "$_options_view" "$_params_view" "$_other_view")"
	
	_create_string_var _message <<-MESSAGE

		$_HELP_TITLE

		$_help_view

	MESSAGE

	printf '%b' "$_message" | less -XRF
}

function _help_print_usage_error_and_die {
	local _invalid_command="$1"

	local _message

	_create_string_var _message <<-MESSAGE

		Invalid command: $_invalid_command

		$(tput bold)USAGE$(tput sgr0)

		$_HELP_USAGE

	MESSAGE

	printf '%b' "$_message"
	exit 129
}


function _parse_help_args {
	local _other_args
	while [ $# -gt 0 ]; do
		case "$1" in
			-h|--help)
				_lib_run _help_print_full_message
				exit $?
				;;
			*)
				_other_args+="$1 "
				shift
				;;
		esac
	done

	[ ! -z "$_other_args" ] && set -- "${_other_args%% }"
}