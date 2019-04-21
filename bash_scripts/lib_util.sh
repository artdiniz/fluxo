function has {
  list="$1"
  item="$2"

  new_list=$(echo "$list" | sed s/$item//)

  [ "$new_list" == "$list" ] && echo 0 || echo 1
}

function count {
	local to_be_counted="$1"
	local line_count="$(echo -ne "$to_be_counted" | wc -l | xargs)"
	[ "$to_be_counted" == '' ] && local count=0 || local count=$(($line_count + 1))
	echo "$count"
}