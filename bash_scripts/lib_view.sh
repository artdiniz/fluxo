function view_errorline {
	[ -z "$1" ] && local text="Error " || local text="$1"
	echo -e "$(tput setaf 7)$(tput setab 1)$(tput bold) $text $(tput sgr0) "
}

function view_errordot {
	echo -e "$(tput setaf 1 && tput bold)•$(tput sgr0)"
}

function view_join {
	local join_view=""
	for view in "$@"; do
		if [ "$view" != "" ]; then
		local join_view="$(
			echo "$join_view"
			echo
			echo "$view"
		)"
		fi
	done

	join_view="${join_view##[[:space:]]}"
	join_view="${join_view##[[:space:]]}"

	echo -e "$join_view"
}

function _count_start_new_lines {
 	local _text
	if [ ! -z "$1" ]; then
		_text="$1"
	else
		_create_string_var _text < /dev/stdin
	fi

	local _count=0

 	while IFS= read -r _text_line; do
		if [ "$_text_line" = '' ]; then 
			(( _count++ ))
		else
			break
		fi
	done <<< "$(printf '%b' "$_text")"

	printf '%s' "$_count"
}

function _count_end_new_lines {
	local _text
	if [ ! -z "$1" ]; then
		_text="$1"
	else
		_create_string_var _text < /dev/stdin
	fi

	local _text_line_count="$( count "$_text" )"

	local _trimmed_end_text="$( printf '%b' "$_text" )"
	local _trimmed_end_text_line_count="$( count "$_trimmed_end_text" )"

	printf '%s' $(( $_text_line_count - $_trimmed_end_text_line_count ))
}

function _trim_start {
	local _text
	if [ ! -z "$1" ]; then
		_text="$1"
	else
		_create_string_var _text < /dev/stdin
	fi

	local _count=0
	local _started=1
	local _trimmed_start_text=""

 	while IFS= read -r _text_line; do
		if [ $_started -eq 1 ] && [ "$_text_line" = '' ]; then 
			(( _count++ ))
		else
			_started=0
			_trimmed_start_text+="$_text_line\\n"
		fi
	done <<< "$(printf '%b' "$_text")"

	printf '%b' "$_trimmed_start_text"
}

function _trim_end {
	local _text
	if [ ! -z "$1" ]; then
		_text="$1"
	else
		_create_string_var _text < /dev/stdin
	fi

	printf '%b' "$_text" | _reverse_lines | _trim_start | _reverse_lines
}

function _trim_all {
	local _text
	if [ ! -z "$1" ]; then
		_text="$1"
	else
		_create_string_var _text < /dev/stdin
	fi

	printf '%b' "$_text" | _trim_start | _trim_end
}


function _view_join_if_not_empty {
	local _result_var_name="$1"
	shift

	local _result=""

	local _last_view_end_new_line_count=0

	for _view in "$@"; do
		if [ ! -z "$_view" ]; then
			local _new_lines_between_count=0
			local _view_top_new_line_count="$(_count_start_new_lines "$_view")"

			local _trimmed_view="$(_trim_all "$_view")"

			if [ $_last_view_end_new_line_count -gt $_view_top_new_line_count ]; then
				_new_lines_between_count=$_last_view_end_new_line_count
			else
				_new_lines_between_count=$_view_top_new_line_count
			fi
			
			local _new_lines_between=""

			while [ $_new_lines_between_count -gt 0 ]; do
			  _new_lines_between+='\n'
			  (( _new_lines_between_count-- ))
			done
			_result="$_result$_new_lines_between$_trimmed_view"

			_last_view_end_new_line_count="$(_count_end_new_lines "$_view")"
    	fi
  	done

	eval "$_result_var_name=\"\$_result\""
}

function view_git_for_each_ref {
	local branches="$1"
	local git_for_each_ref_args="${@:2}"

  local branches="${branches%%"\n"}"

	local formattedBranches="$(
		echo "$branches" |
		xargs -I %% echo git for-each-ref --color=always "$(echo -e "$git_for_each_ref_args")" \'refs/heads/%%\' | 
    bash -
	)"

	echo "$formattedBranches"
}