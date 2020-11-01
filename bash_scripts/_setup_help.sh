function _help_print_full_message {
	printf '\n%b\n' "Opening help..."

	local _usage_view _options_view _params_view _other_view

	[ "$_HELP_USAGE" ] && _create_string_var _usage_view <<-'USAGE'
		$(tput bold)USAGE$(tput sgr0)
		
		$_HELP_USAGE
	USAGE

	[ "$_HELP_OPTIONS" ] && _create_string_var _options_view <<-'OPTIONS'
		$(tput bold)OPTIONS$(tput sgr0)

		$_HELP_OPTIONS
	OPTIONS

	[ "$_HELP_PARAMS" ] && _create_string_var _params_view <<-'PARAMS'
		$(tput bold)PARAMS$(tput sgr0)
		
		$_HELP_PARAMS
	PARAMS

	[ "$_HELP_OTHER" ] && _create_string_var _other_view <<-'OTHER'
		$(tput bold)===$(tput sgr0)
		
		$_HELP_OTHER
	OTHER

	# $_FLUXO_COMMAND_NAME diff -h | --help
    # --help                                       show detailed instructions

	local _help_view

	_create_string_view_var _help_view <<-'MESSAGE'

		$_HELP_TITLE

		$_usage_view

		$_options_view

		$_params_view

		$_other_view
	MESSAGE

	printf '\e[2A\e[0J'
	printf '%b' "$_help_view" | less -XRF
}

function _help_print_usage_error_and_die {
	local _error_message="$1"

	local _message

	_create_string_var _message <<-MESSAGE

		$_HELP_TITLE

		$(tput bold)Error:$(tput sgr0) $_error_message

		$(tput bold)USAGE$(tput sgr0)

		$_HELP_USAGE
	MESSAGE

	printf '%b' "$_message"
	_error_handling_ignore_next_warning
	exit 129
}

function _parse_help_args {
	local _other_args_count=0
	while [ $# -gt 0 ]; do
		case "$1" in
			-h|--help)
				if [ $_other_args_count -gt 0 ]; then
					_lib_run _help_print_usage_error_and_die "If you want it, --help must be the only option"
				else
					_lib_run _help_print_full_message
					exit $?
				fi
				;;
			*)
				(( _other_args_count++ ))
				shift
				;;
		esac
	done
}