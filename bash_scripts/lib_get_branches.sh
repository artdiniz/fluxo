function filter_branches_in {
    local main_branches="$1"
    local filter_arg_branches="$2"

    if [ -n "$filter_arg_branches" ]; then
      local filter_arg_branches_for_grep="$(echo -e "${filter_arg_branches%%\\n}" | xargs -I %% echo '^%%$' | tr '\n' '|')"

      local branches="$(echo -e "$main_branches" | grep -wE "${filter_arg_branches_for_grep%|}")"
      echo -e "$branches"
    fi
}

function filter_branches_not_in {
    local main_branches="$1"
    local filter_arg_branches="$2"

    if [ -n "$filter_arg_branches" ]; then
      local filter_arg_branches_for_grep="$(echo -e "${filter_arg_branches%%\\n}" | xargs -I %% echo '^%%$' | tr '\n' '|')"

      local branches="$(echo -e "$main_branches" | grep -v -wE "${filter_arg_branches_for_grep%|}")"
	    echo -e "$branches"
    else
      echo -e "$main_branches"
    fi
}

function get_unknown_branches {
  local fluxo_branches_from_file

  if fluxo_branches_from_file="$(read_fluxo_branches_file _fluxo)"; then
    local all_branches="$(git branch --sort="committerdate" --format="%(refname:short)")"
    echo -e "$(filter_branches_not_in "$all_branches" "$fluxo_branches_from_file")"
  else
    printf '%b' "$fluxo_branches_from_file"
  fi
}

function get_unexistent_fluxo_branches   {
  local fluxo_branches_from_file
  
  if fluxo_branches_from_file="$(read_fluxo_branches_file _fluxo)"; then
    local all_branches=$(git branch --format="%(refname:short)")
    local unexistent_branches="$(filter_branches_not_in "$fluxo_branches_from_file" "$all_branches")"
    printf '%b' "$unexistent_branches"
  else
    printf '%b' "$fluxo_branches_from_file"
  fi
  
}

function get_existent_fluxo_branches {
  local fluxo_branches_from_file

  if fluxo_branches_from_file="$(read_fluxo_branches_file _fluxo)"; then
    local all_branches=$(git branch --format="%(refname:short)")
    local existent_branches="$(filter_branches_in "$fluxo_branches_from_file" "$all_branches")"
    printf '%b' "$existent_branches"
  else
    printf '%b' "$fluxo_branches_from_file"
  fi
}
