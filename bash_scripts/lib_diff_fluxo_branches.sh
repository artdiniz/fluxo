#!/usr/bin/env bash 

function diff_fluxo_branches {
    local branches="$(printf %b "$1")"

    local root_dir="$(read_fluxo_file_with_cache "_fluxo_root" "_fluxo")"
    local ignored_files="$(read_fluxo_file_with_cache "_fluxo_ignore" "_fluxo")"
    local change_only_files=$(read_fluxo_file_with_cache "_fluxo_change_only" "_fluxo")
    
    local exclude_ignored_diff_args="$(printf '%b\n' "$ignored_files" | xargs -I %% echo "':(exclude,top)%%'" | tr '\n' ' ')"
    local exclude_change_only_files_diff_arg="$(printf '%b\n' "$change_only_files" | xargs -I %% echo "':(exclude,top)%%'" | tr '\n' ' ')"

    local include_change_only_files_diff_arg="$(printf '%b\n' "$change_only_files" | tr '\n' ' ')"

    local branches_array
    IFS=$'\n' branches_array=($(printf '%s\n' "$branches"))

    local i=1

    while [ $i -lt ${#branches_array[@]} ]; do
        local current_branch="${branches_array[i]}"
        local previous_branch="${branches_array[i-1]}"

        if [ ! -z "$root_dir" ]; then
            git show "$current_branch":"$root_dir" &>/dev/null && git show "$previous_branch":"$root_dir" &>/dev/null
            local status=$?

            if [ $status -eq 0 ]; then
                local relative_dir_diff_arg="--relative='$root_dir'"
            else
                printf '%b\n' "Pasta raíz '$root_dir' foi definida no arquivo _fluxo_root, porém ela não existe nas branches $current_branch ou $previous_branch"
                exit 1 
            fi
        fi

        local main_diff_command="git diff ${relative_dir_diff_arg} -U1000 --minimal --ignore-space-change '$previous_branch'..'$current_branch' -- $exclude_ignored_diff_args $exclude_change_only_files_diff_arg"
        local main_diff="$(bash -c "$main_diff_command")"

        if [ ! -z "$main_diff" ]; then
            printf '%b\n' "$main_diff"
        fi

        if [ ! -z "$change_only_files" ]; then
            local change_only_files_diff_command="git diff ${relative_dir_diff_arg} -U1000 --find-renames --diff-filter=MR --minimal --ignore-space-change '$previous_branch'..'$current_branch' -- $include_change_only_files_diff_arg $exclude_ignored_diff_args"
            local change_only_files_add_remove_diff_command="git diff  ${relative_dir_diff_arg} --diff-filter=AD --name-status --minimal '$previous_branch'..'$current_branch' -- $include_change_only_files_diff_arg $exclude_ignored_diff_args"
            
            local change_only_files_diff="$(bash -c "$change_only_files_diff_command")"
            local change_only_files_add_remove_diff="$(bash -c "$change_only_files_add_remove_diff_command")"

            if [ ! -z "$change_only_files_diff" ]; then
                printf '%b\n' "$change_only_files_diff"
            fi

            if [ ! -z "$change_only_files_add_remove_diff" ]; then
                printf '%b\n' "diff --fluxo a/change_only_files b/change_only_files"
                printf '%b\n' "$change_only_files_add_remove_diff"
            fi
        fi

        (( i++ ))
    done
}
