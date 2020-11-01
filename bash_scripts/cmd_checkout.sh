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

    local all_branches="$(git branch --format="%(refname:short)")"
    local _branch
    _branch="$(_lib_run filter_branches_in "$_branch_name" "$all_branches")"

    if [ -z "$_branch" ]; then
      printf '%b\n' "Branch desconhecida: $_branch_name"
      exit 1
    fi

    rm -r "$_checkout_output_folder" 2&> /dev/null

    git worktree prune

    git worktree add "$_checkout_output_folder" "$_branch_name" > /dev/null

    printf '\nArquivos do passo "%s" disponíveis em:\n    file://%s\n\n' "$_branch" "$(cd $_checkout_output_folder; pwd)"
}
