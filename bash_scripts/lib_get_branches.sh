function filter_branches_in {
    local main_branches="$1"
    local filter_arg_branches="$2"

    if [ -n "$filter_arg_branches" ]; then
      local filter_arg_branches_for_grep="$(printf '%b\n' "${filter_arg_branches%%\\n}" | xargs -I %% echo '^%%$' | tr '\n' '|')"

      local branches="$(printf '%b\n' "$main_branches" | grep -wE "${filter_arg_branches_for_grep%|}")"
      printf '%b\n' "$branches"
    fi
}

function filter_branches_not_in {
    local main_branches="$1"
    local filter_arg_branches="$2"

    if [ -n "$filter_arg_branches" ]; then
      local filter_arg_branches_for_grep="$(printf '%b\n' "${filter_arg_branches%%\\n}" | xargs -I %% echo '^%%$' | tr '\n' '|')"

      local branches="$(printf '%b\n' "$main_branches" | grep -v -wE "${filter_arg_branches_for_grep%|}")"
	    printf '%b\n' "$branches"
    else
      printf '%b\n' "$main_branches"
    fi
}

function get_unknown_branches {
  local fluxo_branches_from_file

  if fluxo_branches_from_file="$(_lib_run read_fluxo_branches_file _fluxo)"; then
    local all_branches="$(git branch --sort="committerdate" --format="%(refname:short)")"
    _lib_run filter_branches_not_in "$all_branches" "$fluxo_branches_from_file"
  else
    printf '%b' "$fluxo_branches_from_file"
  fi
}

function get_unexistent_fluxo_branches   {
  local fluxo_branches_from_file
  
  if fluxo_branches_from_file="$(_lib_run read_fluxo_branches_file _fluxo)"; then
    local all_branches=$(git branch --format="%(refname:short)")
    _lib_run filter_branches_not_in "$fluxo_branches_from_file" "$all_branches"
  else
    printf '%b' "$fluxo_branches_from_file"
  fi
  
}

function get_existent_fluxo_branches {
  local fluxo_branches_from_file

  if fluxo_branches_from_file="$(_lib_run read_fluxo_branches_file _fluxo)"; then
    local all_branches=$(git branch --format="%(refname:short)")
    _lib_run filter_branches_in "$fluxo_branches_from_file" "$all_branches"
  else
    printf '%b' "$fluxo_branches_from_file"
  fi
}
