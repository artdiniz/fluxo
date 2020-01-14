#!/usr/bin/env bash 

. $(cd "$(dirname "$0")" && pwd)"/lib_style.sh"

OK=0
ERROR=1

function fluxo_doctor {
    local error_count=0

    echo

    analyze "unexistent_branches" error_count \
        "✅ 👍 Todas as branches do fluxo existem" \
        "❌ ✋ Algumas branches do fluxo não existem nesse repositório local."

    echo
    
    analyze "branches_commits_sync_status" error_count \
        "✅ 👍 Todas as branches do fluxo estão com os commits sincronizados" \
        "❌ ✋ Algumas branches estão desincronizadas. Siga as instruções abaixo para sincronizá-las"
        
    echo
    
    printf '\n%s' "$(style $BOLD "Resultado geral: ")"
    if [ $error_count -gt 0 ]; then
        [ $error_count -eq 1 ] && local pluralized_error_word="erro" || local pluralized_error_word="erros"

        printf '%s\n\n'  "$(style $RED$BOLD$UNDERLINE "$error_count $pluralized_error_word")"
        exit $ERROR
    else
        printf '%s\n\n' "🌈✨ $(style $GREEN$BOLD "Sem erros")"
        exit $OK
    fi
}


function analyze {
    local function_name="$1"
    local error_count_var_name="$2"
    local current_error_count=${!error_count_var_name}
    local success_message="$3"
    local failed_message="$4"

    local result=""
    
    _error_handling_ignore_next_warning
    if ! result="$($function_name)" ; then
        _error_handling_reset_warning
        current_error_count=$(( current_error_count + 1 ))
        printf '%s\n' "$failed_message"
    else
        _error_handling_reset_warning
        printf '%s\n' "$success_message"
    fi

    if [ ! -z "$result" ]; then
        printf '\n%s\n' "$result" | sed 's/^/    /'
    fi

    eval "$error_count_var_name=$current_error_count"
}

function unexistent_branches {
    local unexistent_branches

    if ! unexistent_branches="$(_lib_run get_unexistent_fluxo_branches)"; then
        printf '%s\n' "$unexistent_branches"
        return $ERROR
    elif [ ! -z "$unexistent_branches" ]; then
        printf '%s\n' "$unexistent_branches" | sed 's/^/    • /'
        return $ERROR
    else
        return $OK
    fi
}

function branches_commits_sync_status {
    local known_branches
    known_branches="$(_lib_run get_existent_fluxo_branches | grep -v '_fluxo')"

    local branches_sync_status=0

    IFS=$'\n'; known_branches=($known_branches); unset IFS;

    local known_branches_length=${#known_branches[@]}
    for (( index=1 ; index<$known_branches_length ; index++ )) ; do
        local branch="${known_branches[index]}"
        local previous_branch="${known_branches[index-1]}"

        local number_of_commits="$(_lib_run count "$(git log --no-merges --format="%h" $previous_branch ^$branch)")"
        if [ $number_of_commits -gt 0 ]; then
            (( branches_sync_status++ ))

            local new_commits_log=$(
            git log --no-merges \
                --format="– $(tput setaf 6)%h$(tput sgr0)$(tput bold) by $(tput sgr0)%aN (%cr)%n%n  Commit message: %B%n" \
                $previous_branch ^$branch
            )

            local new_commits_log_info="$(printf %s "$new_commits_log" | head -n1)"
            
            local new_commits_log_message="$(printf %s "$new_commits_log" | tail -n +3)"
            local new_commits_log_message_first_line="$(printf %s "$new_commits_log_message" | head -n1)"
            local new_commits_log_message_rest="$(printf %s "$new_commits_log_message" | tail -n +2)"

            local pluralized_commit_word
            local pluralized_commit_exists_word
            if [ $number_of_commits -eq 1 ]; then
                pluralized_commit_word="commit"
                pluralized_commit_exists_word="existe"
            else
                pluralized_commit_word="commits"
                pluralized_commit_exists_word="existem"
            fi
            
            echo
            echo "$( tput setaf 6)$( tput smul)$( tput bold)$number_of_commits $pluralized_commit_word$(tput sgr0) da branch $(tput setaf 5)$(tput smul)$(tput bold)$previous_branch$(tput sgr0) não $pluralized_commit_exists_word na branch $(tput setaf 5)$(tput smul)$(tput bold)$branch$(tput sgr0)"
            echo
            printf %s "$new_commits_log_info" | sed 's/^/        /'
            printf %s "$new_commits_log_message_first_line" | sed 's/^/        /'
            printf %s "$new_commits_log_message_rest" | sed 's/^/                        | /'
            
            echo
            echo "Execute o seguinte comando:"
            echo "    git fluxo rebase $previous_branch $branch"
            echo
        fi
    done

    return $branches_sync_status
}
