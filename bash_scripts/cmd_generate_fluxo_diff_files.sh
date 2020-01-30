#!/usr/bin/env bash

FLUXO_DIFF_HELP_MESSAGE="\
GIT-FLUXODIFF

$(tput bold)USAGE$(tput sgr0)

  git fluxo diff 
  git fluxo diff [ <some-fluxo-branch> | -a | --all ]
  git fluxo diff [ <any-branch>..<any-other-branch> ]
  git fluxo diff ( -o | --output-files ) [<output-directory>]

  git fluxo diff [ ( -o | --output-files ) <output-directory> ] [ <some-fluxo-branch> | -a | --all ] [ <any-branch>..<any-other-branch> ]

  git fluxo diff -h | --help

$(tput bold)PARAMS$(tput sgr0)

  <some-fluxo-branch>
      is a fluxo branch you want to get the diff off. Defaults to current branch.
      The '_fluxo_bnranches' file will be read to determine wich branch is the previous fluxo branch.

  <any-branch>..<any-other-branch>
      is any set of branches you want to diff using _fluxo_* file rules

$(tput bold)ACTIONS$(tput sgr0)

  -h | --help      show detailed instructions.
  -a | --all       diff all branches following '_fluxo_branches' file.
  -o | --output    generates diff files in <output-directory>.
"

function print_diff_full_usage {
  printf '\n%s\n' "$FLUXO_DIFF_HELP_MESSAGE"
}

function print_diff_usage_and_die {
  printf '\n%s\n' "$FLUXO_DIFF_HELP_MESSAGE"
  exit 1
}

. "$_FLUXO_SCRIPTS_DIR/lib_diff_fluxo_branches.sh"
. "$_FLUXO_SCRIPTS_DIR/cmd_show_fluxo.sh"

function find_previous_for_from {
    local _item_name="$1"
    local _list="$2"

    local _current_item_name _previous_item_name
    while read -r _current_item_name; do
        if [ "$_current_item_name" = "$_item_name" ]; then
            printf %s "$_previous_item_name"
            return
        fi
        _previous_item_name="$_current_item_name"
    done <<< "$(printf '%b' "$_list")"
}

function parse_args {
    local branches_arg branches_var_name="$1"
    local output_directory_arg output_directory_var_name="$2"

    shift
    shift

    local should_diff_all_branches=-1
    local first_branch_arg second_branch_arg

    local BRANCHES_ARGS=""

    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                print_full_usage | less -XRF
                clear
                exit $?
                ;;
            -o|--output-files)
                shift
                if [ -z "$1" ]; then
                    printf '\n%s\n' "No output folder dir provided"
                    print_diff_usage_and_die
                fi
                output_directory_arg="$1"
                shift
                ;;
            -a|--all)
                should_diff_all_branches=0
                shift
                ;;
            *)
                BRANCHES_ARGS+="$1 "
                shift
                ;;
        esac
    done

    [ ! -z "$BRANCHES_ARGS" ] && set -- "${BRANCHES_ARGS%% }"

    if [ $# -gt 0 ] && [ $should_diff_all_branches -eq 0 ]; then
        printf '\n%s\n%s\n' "You selected both '--all' branches option and passed a specific branch argument '$@' to diff" "You must choose either all branches or a specific set of branches to diff"
        print_diff_usage_and_die
    fi

    if [ $# -gt 2 ]; then
        printf '\n%s\n%s\n' "More than one branch argument provided" "To diff between to branches you must use the syntax: branch1..branch2"
        print_diff_usage_and_die
    fi

    local fluxo_branches="$(get_existent_fluxo_branches)"

    if [ $should_diff_all_branches -eq 0 ]; then
        branches_arg="$fluxo_branches"
    else
        local first_branch_arg="$(printf '%s' "$1" | awk '{ split($0,list,/\.\./); print list[1] }')"
        local second_branch_arg="$(printf '%s' "$1" | awk '{ split($0,list,/\.\./); print list[2] }')"

        if [ -z "$first_branch_arg" ]; then
            local current_branch="$(git rev-parse --abbrev-ref HEAD)"
            
            local previous_branch
            previous_branch="$(find_previous_for_from "$current_branch" "$fluxo_branches")"

            if [ -z "$previous_branch" ]; then
                printf '\n%s\n\n' "$(view_errorline) Current branch '$current_branch' is not a fluxo branch"
                exit 1
            fi

            branches_arg="$previous_branch\\n$current_branch"
        elif [ ! -z "$first_branch_arg" ] && [ -z "$second_branch_arg" ]; then
            local previous_branch
            previous_branch="$(find_previous_for_from "$first_branch_arg" "$fluxo_branches")"

            if [ -z "$previous_branch" ]; then
                printf '\n%s\n\n' "$(view_errorline) Argument'$first_branch_arg' is not a fluxo branch"
                exit 1
            fi

            branches_arg="$previous_branch\\n$first_branch_arg"
        elif [ ! -z "$first_branch_arg" ] && [ ! -z "$second_branch_arg" ]; then
            branches_arg="$first_branch_arg\\n$second_branch_arg"
        else
            print_diff_usage_and_die
        fi
    fi

    eval "$branches_var_name=\$branches_arg"
    eval "$output_directory_var_name=\$output_directory_arg"
}

function generate_fluxo_diff_files {
    local branches 
    local output_directory

    parse_args branches output_directory "$@"

    branches="$(printf %b "$branches")"
    
    local tmp_folder=$(mktemp -d)
    function remove_tmp_folder {
        rm -rf "$1"
    }
    trap "remove_tmp_folder $tmp_folder" EXIT

    local branches_array
    IFS=$'\n' branches_array=($(printf '%s\n' "$branches"))

    local qt_files=$(( ${#branches_array[@]} - 1 ))
    local digits="${#qt_files}"

    local i
    for ((i=1; i<${#branches_array[@]}; i++)); do
        local current_branch="${branches_array[i]}"
        local previous_branch="${branches_array[i-1]}"

        local diff_file_name="$tmp_folder/$(printf %0"$digits"d $i)-$current_branch.diff"

        printf '%b\n' "$(_lib_run diff_fluxo_branches "$previous_branch\\n$current_branch")" 2>> /dev/null 1>> "$diff_file_name"
    done

    if [ -z "$output_directory" ]; then
        local file_name
        while read -r file_name; do
            printf '\n%b\n' "$(cat "$tmp_folder"/"$file_name")"
        done <<< "$(ls "$tmp_folder")"

        rm -r $tmp_folder
    else
        mkdir -p "$output_directory"_new
        mv $tmp_folder/* "$output_directory"_new
        [ -r "$output_directory" ] && rm -r "$output_directory" 2> /dev/null

        mv "$output_directory"_new "$output_directory"

        printf '\n%b\n\n' "Created $(style $BOLD$PURPLE $qt_files) diff files in $(style $UNDERLINE$CYAN `pwd $output_directory`/$output_directory/)"

        ls $output_directory | xargs -I {} bash -c "printf '%b' \"    $(style $GREEN "•") $(style $GREY {})\n\""
        printf '\n'
    fi

}