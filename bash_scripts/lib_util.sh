function has {
  list="$1"
  item="$2"

  new_list=$(echo "$list" | sed s/$item//)

  [ "$new_list" == "$list" ] && echo 0 || echo 1
}

function count {
	local to_be_counted="$1"
	local line_count="$(printf '%b' "$to_be_counted" | sed -n '$=')"
	[ -z "$line_count" ] && local count=0 || local count=$line_count
	printf '%s' "$count"
}

function _count_lines {
	local _to_be_counted="$1"
	if [ ! -z "$1" ]; then
		_to_be_counted="$1"
	else
		_create_string_var _to_be_counted < /dev/stdin
	fi

	local _line_count="$(printf '%b' "$_to_be_counted" | wc -l | xargs)"
	printf '%s' "$_line_count"
}

function _count_words {
	local _to_be_counted="$1"

  if [ ! -z "$_to_be_counted" ]; then
	  printf '%s' "$_to_be_counted" | awk '{print NF}'
  else
    printf '0'
  fi
}

function _reverse_lines {
	local _text
	if [ ! -z "$1" ]; then
		_text="$1"
	else
		_create_string_var _text < /dev/stdin
	fi

	printf '%b' "$_text" | sed -n '1! G;$ p;h'
}

function _create_string_var {
	local _message_var_name
	_message_var_name="$1"

	IFS= read -rd '' "$_message_var_name" || [ $? -eq 1 ] && :
}

_state_reading_normal_text=2
_state_escape_next=1

_state_starting_any_expansion=10

_state_reading_simple_expansion=21
_state_reading_parenthesis_expansion=31
_state_reading_brace_expansion=41

_state_end_simple_expansion=22
_state_end_parenthesis_expansion=32
_state_end_brace_expansion=42

_state_initial=$_state_reading_normal_text

function _set_state {
	local _char="$1"
	local _previous_state=$2

	if [ $_previous_state -eq $_state_escape_next ] ; then
		printf '%s' $_state_reading_normal_text
		return
	fi

	if [ $_previous_state -eq $_state_end_simple_expansion ] \
	|| [ $_previous_state -eq $_state_end_parenthesis_expansion ] \
	|| [ $_previous_state -eq $_state_end_brace_expansion ]; then
		if [ "$_char" != '$' ]; then
			if [ "$_char" = '\' ]; then
				printf '%s' $_state_escape_next
			else
				printf '%s' $_state_reading_normal_text
			fi
		fi
		return
	fi

	if [ $_previous_state -eq $_state_reading_normal_text ] && [ "$_char" != '$' ]; then
		if [ "$_char" = '\' ]; then
			printf '%s' $_state_escape_next
		else
			printf '%s' $_state_reading_normal_text
		fi

		return
	fi

	if [ $_previous_state -eq $_state_reading_normal_text ] && [ "$_char" = '$' ]; then
		printf '%s' $_state_starting_any_expansion
		return
	fi

	if [ $_previous_state -eq $_state_end_simple_expansion ] \
	|| [ $_previous_state -eq $_state_end_parenthesis_expansion ] \
	|| [ $_previous_state -eq $_state_end_brace_expansion ]; then
		if [ "$_char" = '$' ]; then
			printf '%s' $_state_starting_any_expansion
		else
			printf '%s' $_state_reading_normal_text
		fi

		return
	fi

	if [ $_previous_state -eq $_state_starting_any_expansion ] && [ "$_char" != '(' ] && [ "$_char" != '{' ]; then
		printf '%s' $_state_reading_simple_expansion
		return
	fi

	if [ $_previous_state -eq $_state_starting_any_expansion ] && [ "$_char" = '(' ]; then
		printf '%s' $_state_reading_parenthesis_expansion
		return
	fi

	if [ $_previous_state -eq $_state_starting_any_expansion ] && [ "$_char" = '{' ]; then
		printf '%s' $_state_reading_brace_expansion
		return
	fi

	if [ $_previous_state -eq $_state_reading_simple_expansion ] && [ "$_char" = ' ' ]; then
		printf '%s' $_state_end_simple_expansion
		return
	elif [ $_previous_state -eq $_state_reading_simple_expansion ] && [ "$_char" = $'\n' ]; then
		printf '%s' $_state_end_simple_expansion
		return
	elif [ $_previous_state -eq $_state_reading_simple_expansion ]; then
		printf '%s' $_state_reading_simple_expansion
		return
	fi

	if [ $_previous_state -eq $_state_reading_parenthesis_expansion ] && [ "$_char" = ')' ]; then
		printf '%s' $_state_end_parenthesis_expansion
		return
	elif [ $_previous_state -eq $_state_reading_parenthesis_expansion ]; then
		printf '%s' $_state_reading_parenthesis_expansion
		return
	fi

	if [ $_previous_state -eq $_state_reading_brace_expansion ] && [ "$_char" = '}' ]; then
		printf '%s' $_state_end_brace_expansion
		return
	elif [ $_previous_state -eq $_state_reading_brace_expansion ]; then
		printf '%s' $_state_reading_brace_expansion
		return
	fi

	exit 1
} 

__EVAL_COUNTER=0
function __eval {
	local _initial_eval_text="$1"

	__deep_eval "$_initial_eval_text"
}

function __deep_eval {
	local _deep_eval_text="$1"
	local _previous_deep_eval_text="$2"

	local _temp_deep_eval_value
	local _final_eval_value

	eval "_temp_deep_eval_value=\"$_deep_eval_text\""
	eval "_final_eval_value=\"$_temp_deep_eval_value\""

	# if [ "$_deep_eval_text" != "$_temp_deep_eval_value" ]; then
		
	# 	__deep_eval "$_temp_deep_eval_value" "$_deep_eval_text"
	# else
		printf '%b' "$_final_eval_value"
	# fi 
}


function _create_string_view_var {
	local _message_var_name
	_message_var_name="$1"

	local _text
	if [ ! -z "$2" ]; then
		printf '%b' "$2" | _create_string_var _text
	else
		_create_string_var _text < /dev/stdin
	fi

	local _total_result=""

	local _char_count=${#_text}
	local i=0

	local _current_result_text=""
	local _current_var_text=""

	local _prev_state=$_state_initial

	while IFS='' read -r -d '' -n 1 _current_char; do
		local _current_state="$(_set_state "$_current_char" $_prev_state)"

		# printf '%s – %q # %s\n===\n' "$i" "$_current_char" "$_current_state"

		if [ $_current_state -eq $_state_reading_normal_text ]; then
			_current_result_text+="$_current_char"
		fi

		if [ $_current_state -eq $_state_starting_any_expansion ]; then
			_current_var_text+="$_current_char"
		fi

		if [ $_current_state -eq $_state_reading_simple_expansion ] \
		|| [ $_current_state -eq $_state_reading_parenthesis_expansion ] \
		|| [ $_current_state -eq $_state_reading_brace_expansion ]; then
			_current_var_text+="$_current_char"
		fi

		if [ $_current_state -eq $_state_end_parenthesis_expansion ] \
		|| [ $_current_state -eq $_state_end_brace_expansion ]; then
			_current_var_text+="$_current_char"
			
			# printf '1Total:\n===|%b|===\nCurrent:===|%q|===\nVar:===|%b|===\n*************\n\n' "$_total_result" "$_current_result_text" "$_current_var_text"

			local _temp_result_text			
			_create_string_var _evalued_text < <(__eval "$_current_var_text")

			_view_join_if_not_empty _temp_result_text "$_total_result" "$_current_result_text" "$_evalued_text"

			_total_result="$_temp_result_text"

			_current_result_text=""
			_current_var_text=""
		fi

		if [ $_current_state -eq $_state_end_simple_expansion ]; then
			# printf '2Total:\n===|%b|===\nCurrent:===|%q|===\nVar:===|%b|===\n*************\n\n' "$_total_result" "$_current_result_text" "$_current_var_text"
			
			local _evalued_text			
			_create_string_var _evalued_text < <(__eval "$_current_var_text")

			_view_join_if_not_empty _temp_result_text "$_total_result" "$_current_result_text" "$_evalued_text"

			_total_result="$_temp_result_text"

			_current_result_text="$_current_char"
			_current_var_text=""
		fi
		_prev_state=$_current_state
	done < <(printf '%b' "$_text")

	# printf '3Total:\n===|%b|===\nCurrent:===|%q|===\nVar:===|%b|===\n*************\n\n' "$_total_result" "$_current_result_text" "$_current_var_text"			

	local _evalued_text			
	_create_string_var _evalued_text < <(__eval "$_current_var_text")

	_view_join_if_not_empty _temp_result_text "$_total_result" "$_current_result_text" "$_evalued_text"

	_total_result="$_temp_result_text"

	eval "$_message_var_name=\$_total_result"
}