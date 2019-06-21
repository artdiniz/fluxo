#!/bin/bash -e

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

  local new_commits_log_first_line="$(echo -ne "$new_commits_log" | head -n1)"
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
    # Pass the action through to git-rebase.
    git rebase --$action ||
      exit $? # if it drops to shell again, stop again.
    all_involved_branches=`git log --format=%s refs/hidden/octomerge -1`
    all_involved_branches="${all_involved_branches#merging }"
    
    ordered_affected_branches="$(echo -ne "$all_involved_branches" | tr ' ' '\n' | tail -n +2)"

    new_commits_branch="$(echo -ne "$all_involved_branches" | tr ' ' '\n' | head -n1)"
    next_branch="$(echo -ne "$ordered_affected_branches" | head -n1)"
      
    echo
    print_status_message
    echo
    wait_confirmation

  else
    new_commits_branch="$1"
    next_branch="$2"

    fluxo_ordered_branches=$(show_fluxo --raw --existent)

    fluxo_status=$?
    if [ $fluxo_status != 0 ]; then
      echo -ne "$fluxo_ordered_branches"
      echo
      echo
      exit $fluxo_status
    fi
    
    unexistent_branches="$(show_fluxo --raw --unexistent)"
    unexistent_branches_count="$(count "$unexistent_branches")"

    if [ $unexistent_branches_count -gt 0 ]; then
      echo -e "$(show_fluxo --unexistent)"
      echo
      echo "All branches must exist. Aborting rebase!"
      echo
      exit 1
    fi

    all_affected_branches="$(git br --contains "$next_branch" --format="%(refname:short)")"

    ordered_affected_branches="$(filter_branches_in "$fluxo_ordered_branches" "$all_affected_branches")"
    unknown_to_fluxo_branches="$(
      filter_branches_in "$(show_fluxo --raw --unknown)" "$all_affected_branches"
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
      
      # # The money shot: rebase the octomerge onto the new_commits_branch.
      git rebase --preserve-merge --onto $new_commits_branch --root refs/hidden/octomerge ||
      exit $? # if the rebase drops to shell, stop here.
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
  commitsDistanceString=$(
    echo -ne "$ordered_affected_branches" | 
    awk '{OFS="";}NR>1{print "git log --no-merges --format=%h " "\\\47"$1"\\\47 ^\\\47"last"\\\47 | wc -l | xargs"} {last=$1}' |
    xargs -I {} bash -c '{}'
  )
  IFS=$'\n'; commitsDistance=($commitsDistanceString); commitsDistanceBackwards=($commitsDistanceString); unset IFS;

  # Reversing $commitsDistance because 
  #   the last distance in it is the distance between HEAD and the nearest branch top rebased commit
  length=$(echo "$commitsDistanceString"| wc -l | xargs)
  for (( idx=$length ; idx>0 ; idx-- )) ; do
    commitsDistanceBackwards[$(($length - $idx))]=$(echo "${commitsDistance[(idx - 1)]}")
  done

  # Getting commits distance from octomerge HEAD (and not from one branch to another), 
  #   by summing de distances in the $commitsDistanceBackwards array
  for index in ${!commitsDistanceBackwards[@]}; do
    currentValue=$(echo "${commitsDistanceBackwards[index]}")
    if [ $index != 0 ]; then
      previous_position=$(($index - 1))
      previousValue=$(echo "${commitsDistanceBackwards[previous_position]}")

      commitsDistanceBackwards[$index]=$(($currentValue + $previousValue))
    else
      commitsDistanceBackwards[$index]=$(($currentValue + 2))
    fi
  done

  new_commit_list=$(
    echo `git log --topo-order --format='%H' | head -n+2 | tail -n1` &&
    echo -ne "${commitsDistanceBackwards[@]}" |
    tr ' ' '\n' | 
    xargs -I {} bash -c "git log --topo-order --format='%H' | head -n +{} | tail -n1"
  )

  IFS=$'\n'; new_commit_list=($new_commit_list); unset IFS;

  rebased_length=${#new_commit_list[@]}
  rebase_integrity_status=0

  echo "Verificação de integridade dos rebases:"
  echo

  for (( index=$rebased_length ; index>0 ; index-- )) ; do
    local branch=${branches_list[rebased_length - index]}
    local old_branch_head_hash="$(git rev-parse --short $branch)"
    local old_branch_head_commit_message_first_line="$(git show --format="%B" $branch | head -n1)"

    local new_branch_head_hash="$(git show --format=%h ${new_commit_list[index - 1]} | head -n1)"
    local new_branch_head_commit_message_first_line="$(git show --format="%B" ${new_commit_list[index - 1]} | head -n1)"


    if [ "$old_branch_head_commit_message_first_line" != "$new_branch_head_commit_message_first_line" ]; then    
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
    local new_branch_head_hash="$(git show --format=%h ${new_commit_list[index - 1]} | head -n1)"
    local new_branch_head_full_hash="$(git show --format=%H ${new_commit_list[index - 1]} | head -n1)"
    
    git br -f $branch $new_branch_head_full_hash
    echo "Rebased $branch | $old_branch_head_hash -> $new_branch_head_hash"
  done

  git checkout -q ${branches_list[0]}
  git update-ref -d refs/hidden/octomerge

  echo "Tchau!"

}