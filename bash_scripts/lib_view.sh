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

function view_git_for_each_ref {
	branches=$1
	git_for_each_ref_args="${@:2}"

	formattedBranches="$(
		echo -ne "$branches" |
		xargs -I {} echo "git for-each-ref $(echo -e "$git_for_each_ref_args") --color=always 'refs/heads/{}'" | 
		bash -
	)"

	echo -e "${formattedBranches%"\n"}"
}