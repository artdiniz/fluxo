#!/bin/bash

function fluxo_doctor {
    local known_branches="$(show_fluxo --raw --existent | grep -v '_fluxo')"

    local branches_sync_status=0
    # show_fluxo --raw --unknown | grep -v '_fluxo'

    IFS=$'\n'; known_branches=($known_branches); unset IFS;

    local known_branches_length=${#known_branches[@]}
    for (( index=1 ; index<$known_branches_length ; index++ )) ; do
        local branch="${known_branches[index]}"
        local previous_branch="${known_branches[index-1]}"

        local number_of_commits="$(count "$(git log --no-merges --format="%h" $previous_branch ^$branch)")"
        if [ $number_of_commits -gt 0 ]; then
            (( branches_sync_status++ ))

            local new_commits_log=$(
            git log --no-merges \
                --format="– $(tput setaf 6)%h$(tput sgr0)$(tput bold)' by '$(tput sgr0)%aN \(%cr\)%n%n'  Commit message: '%B%n\ " \
                $previous_branch ^$branch
            )

            local new_commits_log_first_line="$(echo -ne "$new_commits_log" | head -n1)"
            local new_commits_log_rest="$(echo -ne "$new_commits_log" | tail -n +2)"
            
            echo
            echo "$( tput setaf 6)$( tput smul)$( tput bold)$number_of_commits commits$(tput sgr0) da branch $(tput setaf 5)$(tput smul)$(tput bold)$previous_branch$(tput sgr0) não existem na branch $(tput setaf 5)$(tput smul)$(tput bold)$branch$(tput sgr0)"
            echo
            echo -ne "$new_commits_log_first_line" | xargs -I {} bash -c 'echo -ne "        {}\n"'
            echo -ne "$new_commits_log_rest" | xargs -I {} bash -c 'echo -ne "        {}\n"'
            
            echo
            echo "Execute o seguinte comando:"
            echo "    git fluxo rebase $previous_branch $branch"
            echo
        fi
    done

    if [ $branches_sync_status -gt 0 ]; then
        echo
        echo "❌ ✋ Brannches estão desincronizadas. Siga as instruções acima para sincronizá-las"
        echo
        exit 1
    else
        echo
        echo "✅ 👍 Branches sincronizadas"
        echo
        exit
    fi

}