#!/bin/bash -e

. $(cd "$(dirname "$0")" && pwd)"/lib_style.sh"

function printBranchesOrderedByFluxo {
    echo -en "$branches" |
    xargs -I {} echo {} |
    grep -v doing |
    grep -v "gh-pages" 
}

function read_fluxo_file {
    local FILE_NAME="$1"
    local FLUXO_BRANCH_NAME="_fluxo"
    
    git show "$FLUXO_BRANCH_NAME":"$FILE_NAME" &> /dev/null
    local status=$?

    if [ $status -eq 0 ]; then
        local ignore_file_content="$(git show $FLUXO_BRANCH_NAME:$FILE_NAME)"
        if [ ! -z "$ignore_file_content" ]; then
            echo -ne "$ignore_file_content"
        fi
    fi
}

function generate_fluxo_diff_files {
    [ -z "$1" ] && local dest_folder="_fluxo_diff_files" || local dest_folder=$1
    local project_dir="$(pwd)"
    
    local tmp_folder=$(mktemp -d)
    function remove_tmp_folder {
        rm -rf "$1"
    }
    trap "remove_tmp_folder $tmp_folder" EXIT

    branches="$(show_fluxo --existent --raw)"

    status="$?"
    if [ $status != 0 ]; then
        echo -e "$branches\n"
        exit $status
    fi

    local root_dir="$(read_fluxo_file "_fluxo_root")"
    local ignored_files="$(read_fluxo_file "_fluxo_ignore")"
    local change_only_files=$(read_fluxo_file "_fluxo_change_only")
    
    local exclude_ignored_diff_args="$(echo -e "$ignored_files" | xargs -I %% echo "':(exclude)$project_dir/%%'" | tr '\n' ' ')"
    local exclude_change_only_files_diff_arg="$(echo -e "$change_only_files" | xargs -I %% echo "':(exclude)$project_dir/%%'" | tr '\n' ' ')"

    local include_change_only_files_diff_arg="$(echo -e "$change_only_files" | xargs -I %% echo "%%" | tr '\n' ' ')"

    IFS=$'\n' branches_array=($(printBranchesOrderedByFluxo))

    local qt_files=$(( ${#branches_array[@]} - 1 ))
    local digits="${#qt_files}"

    for ((i=1; i<${#branches_array[@]}; i++)); do
        local current_branch="${branches_array[i]}"
        local previous_branch="${branches_array[i-1]}"

        if [ ! -z "$root_dir" ]; then
            git show "$current_branch":"$root_dir" &>/dev/null && git show "$previous_branch":"$root_dir" &>/dev/null
            local status=$?

            if [ $status -eq 0 ]; then
                local relative_dir_diff_arg="--relative='$root_dir'"
            else
                echo -e "Pasta raíz '$root_dir' foi definida no arquivo _fluxo_root, porém ela não existe nas branches $current_branch ou $previous_branch"
                exit 1 
            fi
        fi

        local main_diff_command="git diff ${relative_dir_diff_arg} -U1000 --minimal '$previous_branch'..'$current_branch' -- $exclude_ignored_diff_args $exclude_change_only_files_diff_arg"
        local main_diff="$(bash -c "$main_diff_command")"

        local diff_file_name="$tmp_folder/$(printf %0"$digits"d $i)-$current_branch.diff"

        echo -e "$main_diff" 2>> /dev/null 1>> "$diff_file_name"

        if [ ! -z "$change_only_files" ]; then
            local change_only_files_diff_command="git diff ${relative_dir_diff_arg} -U1000 -M --diff-filter=MR --minimal '$previous_branch'..'$current_branch' -- $include_change_only_files_diff_arg"
            local change_only_files_add_remove_diff_command="git diff  ${relative_dir_diff_arg} --diff-filter=AD --name-status --minimal '$previous_branch'..'$current_branch' -- $include_change_only_files_diff_arg"
            
            local change_only_files_diff="$(bash -c "$change_only_files_diff_command")"
            local change_only_files_add_remove_diff="$(bash -c "$change_only_files_add_remove_diff_command")"

            if [ ! -z "$change_only_files_diff" ]; then
                echo -e "$change_only_files_diff" 2>> /dev/null 1>> "$diff_file_name"
            fi

            if [ ! -z "$change_only_files_add_remove_diff" ]; then
                echo -e "diff --fluxo a/change_only_files b/change_only_files" 2>> /dev/null 1>> "$diff_file_name"
                echo -e "$change_only_files_add_remove_diff" 2>> /dev/null 1>> "$diff_file_name"
            fi
        fi
    done

    rm -r "$dest_folder" 2> /dev/null
    mkdir -p $dest_folder
    mv $tmp_folder/* $dest_folder

    echo
    echo -e "Created $(style $BOLD$PURPLE $qt_files) diff files in $(style $UNDERLINE$CYAN `pwd $dest_folder`/$dest_folder/)"
    echo

    ls $dest_folder | xargs -I {} bash -c "echo -ne \"    $(style $GREEN "•") $(style $GREY {})\n\""
    echo
}