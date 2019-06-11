function filter_branches_in {
    local main_branches="$1"
    local filter_arg_branches="$2"

    local filter_arg_branches_for_grep=$(echo -e "$filter_arg_branches" | tr '\n' '|')

    local branches="$(echo -e "$main_branches" | grep -wE "${filter_arg_branches_for_grep%|}")"
	echo -e "$branches"
}

function filter_branches_not_in {
    local main_branches="$1"
    local filter_arg_branches="$2"

    local filter_arg_branches_for_grep=$(echo -e "$filter_arg_branches" | tr '\n' '|')

    local branches="$(echo -e "$main_branches" | grep -v -wE "${filter_arg_branches_for_grep%|}")"
	echo -e "$branches"
}

function get_unknown_branches {
  local fluxo_branches_from_file="$1"
  local all_branches=$(git br --sort="committerdate" --format="%(refname:short)")

  echo -e "$(filter_branches_not_in "$all_branches" "$fluxo_branches_from_file")"
}

function get_unexistent_fluxo_branches   {
  local fluxo_branches_from_file="$1"
  local all_branches=$(git br --format="%(refname:short)")

  echo -e "$(filter_branches_not_in "$fluxo_branches_from_file" "$all_branches")"
}

function get_existent_fluxo_branches {
  local fluxo_branches_from_file="$1"
  local all_branches=$(git br --format="%(refname:short)")

  echo -e "$(filter_branches_in "$fluxo_branches_from_file" "$all_branches")"
}