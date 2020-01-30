function _help_create_message {
	local _message_var_name
	_message_var_name="$1"

	IFS= read -d '' -r $_message_var_name
}

function _help_print_full_message {
	local _message

	_help_create_message _message <<-MESSAGE

		$_HELP_TITLE

		$(tput bold)USAGE$(tput sgr0)

		$_HELP_USAGE

		$_HELP_DETAILS

	MESSAGE

	printf '%b' "$_message" | less -XRF
}

function _help_print_usage_error_and_die {
	local _invalid_command="$1"

	local _message

	_help_create_message _message <<-MESSAGE

		Invalid command: "$_invalid_command"

		$(tput bold)USAGE$(tput sgr0)
		$_HELP_USAGE

	MESSAGE

	printf '%b' "$_message"
	exit 129
}