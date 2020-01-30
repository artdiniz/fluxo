function has {
  list="$1"
  item="$2"

  new_list=$(echo "$list" | sed s/$item//)

  [ "$new_list" == "$list" ] && echo 0 || echo 1
}

function count {
	local to_be_counted="$1"
	local line_count="$(printf '%b' "$to_be_counted" | wc -l | xargs)"
	[ "$to_be_counted" == '' ] && local count=0 || local count=$(($line_count + 1))
	printf '%s' "$count"
}

function _count_words {
	local _to_be_counted="$1"

  if [ ! -z "$_to_be_counted" ]; then
	  printf '%s' "$_to_be_counted" | awk '{print NF}'
  else
    printf '0'
  fi
}

function _reverse {
  local text="$1"

  printf '%b' "$text" | sed -n '1! G;$ p;h'
}