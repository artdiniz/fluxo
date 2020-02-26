#!/usr/bin/env bash

_checkout_output_folder="_fluxo_steps"

_HELP_TITLE="FLUXO-CHECKOUT"

_HELP_USAGE="\
  checkout <branch>
"

_HELP_PARAMS="\
  <branch> A branch que você quer acessar o código
"

_HELP_OTHER="\
  Todo o código em <branch> será colocado na pasta '$_checkout_output_folder'
"

function checkout_fluxo {
    local _branch_name="$1"

    local all_branches=$(git branch --format="%(refname:short)")
    local _branch
    _branch="$(_lib_run filter_branches_in "$_branch_name" "$all_branches")"

    if [ -z "$_branch" ]; then
      printf '%b\n' "Unknown branch named '$_branch_name'"
      exit 1
    fi

    git worktree remove "$_checkout_output_folder"

    git worktree add "$_checkout_output_folder" "$_branch_name"
}
