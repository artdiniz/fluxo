#!/usr/bin/env bash

FLUXO_REBASE_HELP_MESSAGE="\
GIT-FLUXOREBASE

$(tput bold)USAGE$(tput sgr0)

  git fluxo rebase <a-branch-da-aula-que-teve-mudancas> <a-branch-da-proxima-aula>
  git fluxo rebase -h | --continue | --abort | --skip

$(tput bold)ACTIONS$(tput sgr0)

  -h               show detailed instructions
  --continue       continue
  --abort          abort and check out the original branch
  --skip           skip current patch and continue

$(tput bold)PARAMS$(tput sgr0)

  <a-branch-da-aula-que-teve-mudancas> A branch que foi modificada com novos commits
  <a-branch-da-proxima-aula> é a branch da aula seguinte à que foi modificada, caso a branch aula1 tenha sido modificada, é a branch da aula 2
"

HELP_WHY="\
$(tput bold)WHY?$(tput sgr0)

  Quando alteramos e commitamos o código de uma aula, no caso a aula 1, 
  as aulas seguintes ficam desatualizadas: 

  A---B  master ✅
        \\
         C---D---*---* aula1 ✅ (* commits novos)
              \\
               E---F---G aula2 ❌ (sem os commits novos da aula1)
                        \\
                         H---I---J aula3 ❌ (sem os commits novos da aula1)

  Para atualizar a aula 2, precisamos rodar um \`git rebase aula1\` ou um \`git merge aula1\` na aula 2. 
  O resultado seria esse, no caso do rebase:   

  A---B  master ✔︎
        \\
         C---D---*---* aula1 ✅ (* commits novos)
              \\       \\
               \\        E'---F'---G' aula2 ✅ (usando commits novos da aula 1 como base)
                \\
                 E---F---G---H---I---J aula3 ❌ (sem os commits novos da aula 1 e sem os commits rebaseados(') da aula 2)

  Agora, temos que fazer o rebase/merge da aula 2 na aula 3, e assim por diante. 
  Se tívessemos mais 25 aulas, teríamos que faser isso mais 25 vezes!

  Esse comando fará isso para você automaticamente.   
  \`git rebase-fluxo aula1 aula2\` => Passa as mudanças da aula1 para a aula2 e para todas as aulas que vierem depois. 

  A ordem das branches é definida de maneira inteligente por esse comando

"

function wait_confirmation {
  read -p "Você tem certeza de que quer continuar? [N/y] " -n 1 -r
  echo

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo
    echo 'Rebase cancelado! Você escolheu não continuar.'
    if [ ! -z "$1" ]; then
      bash -c "$1"
    fi
    exit
  fi
}

function print_full_usage {
  echo -ne "\n$FLUXO_REBASE_HELP_MESSAGE\n$HELP_WHY"
}

function print_usage_and_die {
  echo -ne "\n$FLUXO_REBASE_HELP_MESSAGE\n"
  exit 1
}

function print_status_message {
  local number_of_commits="$(count "$(git log --no-merges --format="%h" $new_commits_branch ^$next_branch)")"
  local new_commits_log=$(
    git log --no-merges \
      --format="– $(tput setaf 6)%h$(tput sgr0)$(tput bold)' by '$(tput sgr0)%aN \(%cr\)%n%n'  Commit message: '%B%n\ " \
      $new_commits_branch ^$next_branch
  )

  local new_commits_log_first_line="$(echo -ne "$new_commits_log" | sed -n 1p)"
  local new_commits_log_rest="$(echo -ne "$new_commits_log" | tail -n +2)"

PRE_CONFIRM_STATUS_MESSAGE="\
$( tput setaf 6)$( tput smul)$( tput bold)$number_of_commits commits$(tput sgr0) serão aplicados na branch $(tput setaf 5)$(tput smul)$(tput bold)$next_branch$(tput sgr0) e em todas as branches que vêem depois dela:

$(
  echo -ne "$new_commits_log_first_line" | xargs -I {} bash -c 'echo -ne "        {}\n"'
  echo -ne "$new_commits_log_rest" | xargs -I {} bash -c 'echo -ne "        {}\n"'
)

$( tput setaf 5)$( tput smul)$( tput bold)$(count "$ordered_affected_branches") branches$(tput sgr0) serão atualizadas, nessa ordem:

$(
  echo -ne "$ordered_affected_branches" |
  tr ' ' '\n' |
  xargs -I {} bash -c 'echo -ne "        $(tput setaf 5)$( tput bold)•$(tput sgr0) {}\n"'
)

$(
if [ "$unknown_to_fluxo_branches" != '' ]; then
echo -ne "\
$( tput setaf 3)$( tput smul)$( tput bold)$(count "$unknown_to_fluxo_branches") branches$(tput sgr0) desconhecidas não serão atualizadas. 
           Elas não constam no arquivo '_fluxo_branches' e não é possível determinar sua ordem:

$(
  echo -ne "$unknown_to_fluxo_branches" |
  tr ' ' '\n' |
  xargs -I {} bash -c 'echo -ne "        $(tput setaf 3)$( tput bold)•$(tput sgr0) {}\n"'
)
"
fi
)

$(
if [ "$not_affected_branches" != '' ]; then
echo -ne "\
$( tput setaf 3)$( tput smul)$( tput bold)$(count "$not_affected_branches") branches$(tput sgr0) do fluxo $( tput setaf 3)$( tput smul)$( tput bold)não serão$(tput sgr0) atualizadas. Por análise dos commits, a branch $( tput setaf 3)$( tput smul)$( tput bold)$(tput smul)$next_branch$(tput sgr0) veio depois delas:

$(
  echo -ne "$not_affected_branches" |
  tr ' ' '\n' |
  xargs -I {} bash -c 'echo -ne "        $(tput setaf 3)$( tput bold)•$(tput sgr0) {}\n"'
)
"
fi
)
"
  echo -e "$PRE_CONFIRM_STATUS_MESSAGE"
}


function _exit_or_try_to_auto_solve_if_conflict {
  local _rebase_status="$1"
  if [ $_rebase_status -gt 0 ]; then
    if [ $_rebase_status -eq 129 ]; then
      # git cli usage/invalid parameter error must exit early 
      #   to prevent an infinite loop if this script execs a wrong rebase comand somewhere
      exit 129
    elif [ -z "$(git diff --name-only --cached)" ] && [ -z "$(git diff --name-only)" ]; then
      local _commit_message="$(cat .git/rebase-merge/message)"
      printf '\n\n%b\n\n' "[fluxo] Conflict automatically solved. Empty commit was allowed."

      git commit --allow-empty -m "$_commit_message"
      _lib_run rebase_fluxo --continue
      exit $?
    else
      exit $_rebase_status
    fi
  fi
}

function rebase_fluxo {
  total_argc=$#
  while test $# -gt 0
  do
    case "$1" in
    -h|--help)
      print_full_usage | less -XRF
      clear
      exit $?
      ;;
    --continue|--skip|--abort)
      action=${1##--}
      break
      ;;
    --)
      shift
      break
      ;;
    esac
    break
  done

  test $# -eq 2 || [ x$action != x ] || print_usage_and_die

  if [ $# != 2 ]; then
    [ x$action = x ] && usage

    local _rebase_status
    # Pass the action through to git-rebase.
    git rebase --$action
    _rebase_status=$?

    # if it conflicts again, stop or try to solve conflict, again.
    _exit_or_try_to_auto_solve_if_conflict $_rebase_status

    all_involved_branches=`git log --format=%s refs/hidden/octomerge -1`
    all_involved_branches="${all_involved_branches#merging }"
    
    ordered_affected_branches="$(printf '%b' "$all_involved_branches" | tr ' ' '\n' | tail -n +2)"

    new_commits_branch="$(printf '%b' "$all_involved_branches" | tr ' ' '\n' | sed -n 1p)"
    next_branch="$(printf '%b' "$ordered_affected_branches" | sed -n 1p)"

    echo
    print_status_message
    echo
    wait_confirmation

  else
    new_commits_branch="$1"
    next_branch="$2"

    fluxo_ordered_branches=$(get_existent_fluxo_branches)

    fluxo_status=$?
    if [ $fluxo_status != 0 ]; then
      echo -ne "$fluxo_ordered_branches"
      echo
      echo
      exit $fluxo_status
    fi
    
    unexistent_branches="$(get_unexistent_fluxo_branches)"
    unexistent_branches_count="$(count "$unexistent_branches")"

    if [ $unexistent_branches_count -gt 0 ]; then
      echo -e "$(show_fluxo --unexistent)"
      echo
      echo "All branches must exist. Aborting rebase!"
      echo
      exit 1
    fi

    all_affected_branches="$(git branch --contains "$next_branch" --format="%(refname:short)")"

    ordered_affected_branches="$(filter_branches_in "$fluxo_ordered_branches" "$all_affected_branches")"
    unknown_to_fluxo_branches="$(
      filter_branches_in "$(get_unknown_branches)" "$all_affected_branches"
    )"
    not_affected_branches=$(
      filter_branches_not_in "$fluxo_ordered_branches" "$all_affected_branches"
    )

    echo
    print_status_message
    echo
    wait_confirmation

    if [[ $REPLY =~ ^[Yy]$ ]]; then
      tree="$(git log -1 --pretty="%T" `git rev-parse $(echo -ne $ordered_affected_branches | tr ' ' '\n' | tail -n1)`)"
    
      branchesParam="-p `echo $ordered_affected_branches | sed -e's/ / -p /g'`"

      # creates a merge commit on top of all other branches.
      # This commit that has a name with all the branches that are being rebased
      octomerge=$(
        echo 'merging' $new_commits_branch $ordered_affected_branches |
        git commit-tree $tree $branchesParam
      )

      # # This creates a hidden-branch called octomerge that has its HEAD at the octomerge commit created above
      git update-ref refs/hidden/octomerge $octomerge || die "couldn't create branch"
      

      local _rebase_status
      # # The money shot: rebase the octomerge onto the new_commits_branch.
      git rebase --keep-empty --preserve-merge $new_commits_branch refs/hidden/octomerge
      _rebase_status=$?

      # if it conflicts, stop or try to solve conflict.
      _exit_or_try_to_auto_solve_if_conflict $_rebase_status
    fi
  fi

  clear
  echo
  echo "Seguindo sem conflitos de rebase!"

  branches_list=($ordered_affected_branches)


  # When rebased is finishe the HEAD of octomerge hidden branch isn't pointing to the rebased one.
  #   Here we force this
  git update-ref -d refs/hidden/octomerge
  git update-ref refs/hidden/octomerge $(git rev-parse HEAD) || die "couldn't branch"

  # Creating $commitsDistance array.
  #   Each position has the distance between the top rebased commit from one branch to another

  _number_of_commits_between_affected_branches_backwards="$(
    local _last_affected_branch
    while IFS= read -r _affected_branch; do
      if [ ! -z "$_last_affected_branch" ]; then
        printf '%b\n' "$(git log --no-merges --format=%h "$_affected_branch" ^"$_last_affected_branch" | wc -l | xargs)"
      fi
      _last_affected_branch="$_affected_branch"
    done <<<  "$(printf '%b' "$ordered_affected_branches")"
  )"

  _number_of_commits_between_affected_branches="$(_reverse "$_number_of_commits_between_affected_branches_backwards")"

  # Getting every afrfected branch HEAD commit distance from octomerge HEAD (and not from one branch to another), 
  #   first branch HEAD commit is always the second commit (first is the octomerg commmit)
  #   the next branches HEAD distance are found by sequentially summing de distances in $_number_of_commits_between_affected_branches
  #   this results in $_distances_from_octomerge_top
  local _total_distance_from_top=2
  local _distances_from_octomerge_top="$_total_distance_from_top\\n"
  while IFS= read -r _distance; do
    _total_distance_from_top=$(($_total_distance_from_top + $_distance))
    _distances_from_octomerge_top+="$_total_distance_from_top\\n"
  done <<< "$(printf '%b' "$_number_of_commits_between_affected_branches")"

  new_commit_list=$(
    printf '%b' "$_distances_from_octomerge_top" |
    xargs -I {} bash -c "git log --topo-order --format='%H' | head -n +{} | tail -n1"
  )

  IFS=$'\n'; new_commit_list=($new_commit_list); unset IFS;

  rebased_length=${#new_commit_list[@]}
  rebase_integrity_status=0

  echo "Verificação de integridade dos rebases:"
  echo

  for (( index=$rebased_length ; index>0 ; index-- )) ; do
    local branch=${branches_list[rebased_length - index]}
    
    local old_branch_head_hash
    old_branch_head_hash="$(git rev-parse --short $branch)"

    local old_branch_head_commit_message old_branch_head_commit_message_first_line
    old_branch_head_commit_message="$(git show --no-patch --pretty=format:%B $branch)"
    old_branch_head_commit_message_first_line="$(printf '%s' "$old_branch_head_commit_message" | sed -n 1p)"

    local new_branch_head_hash
    new_branch_head_hash="$(git show --no-patch --pretty=format:%h ${new_commit_list[index - 1]} | sed -n 1p)"

    local new_branch_head_commit_message new_branch_head_commit_message_first_line
    new_branch_head_commit_message="$(git show --no-patch --pretty=format:%B ${new_commit_list[index - 1]})"
    new_branch_head_commit_message_first_line="$(printf '%s' "$new_branch_head_commit_message" | sed -n 1p)"

    if [ "$old_branch_head_commit_message" != "$new_branch_head_commit_message" ]; then
      (( rebase_integrity_status++ ))
      local status_message="$(tput setaf 1)x"
    else
      local status_message="$(tput setaf 2)✔︎"
    fi

    echo
    echo "$status_message $(tput setaf 6)$branch$(tput sgr0)"
    echo "    De:    $old_branch_head_hash – $old_branch_head_commit_message_first_line"
    echo "    Para:  $new_branch_head_hash – $new_branch_head_commit_message_first_line"
    echo
  done

  if [ $rebase_integrity_status -gt 0 ]; then
    echo "❌ ✋ Integridade do rebase comprometida. O rebase foi cancelado"
    echo
    echo "Voltando para branch $new_commits_branch"
    git co $new_commits_branch &>/dev/null
    exit 1
  fi

  echo "✅ 👍 Aparentemente tudo certo para o rebase."
  echo "Verifique se as mensagens de commit acima batem uma com a outra."
  echo
  wait_confirmation "echo -e 'Voltando para branch $new_commits_branch\n' && git co $new_commits_branch &>/dev/null"
  echo

  for (( index=$rebased_length ; index>0 ; index-- )) ; do
    local branch=${branches_list[rebased_length - index]}

    local old_branch_head_hash="$(git rev-parse --short $branch)"
    local new_branch_head_hash="$(git show --format=%h ${new_commit_list[index - 1]} | sed -n 1p)"
    local new_branch_head_full_hash="$(git show --format=%H ${new_commit_list[index - 1]} | sed -n 1p)"
    
    git branch -f $branch $new_branch_head_full_hash
    echo "Rebased $branch | $old_branch_head_hash -> $new_branch_head_hash"
  done

  git checkout -q ${branches_list[0]}
  git update-ref -d refs/hidden/octomerge

  echo "Tchau!"

}