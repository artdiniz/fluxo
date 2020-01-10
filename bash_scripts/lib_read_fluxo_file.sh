function read_fluxo_file {
    local FILE_NAME="$1"
    local FLUXO_BRANCH_NAME="$2"

    git show "$FLUXO_BRANCH_NAME":"$FILE_NAME" &> /dev/null
    local status=$?

    if [ $status -eq 0 ]; then
        local file_content="$(git show $FLUXO_BRANCH_NAME:$FILE_NAME)"
        printf '%b' "$file_content"
    else
        return 1
    fi
}

function read_fluxo_file_with_cache {
    local FILE_NAME="$1"
    local FLUXO_BRANCH_NAME="$2"

    local cache_var_name="read_fluxo_file_cache_$FILE_NAME"
    local cache_file_content="${!cache_var_name}"

    if [ ! -z "$cache_file_content" ]; then
        printf '%b' "$cache_file_content"
    else
        local file_content
        file_content="$(read_fluxo_file "$FILE_NAME" "$FLUXO_BRANCH_NAME")"

        local status=$?
        if [ $status -eq 0 ]; then
            eval "$cache_var_name=\$file_content"
            printf '%b' "$file_content"
        else
            return $status
        fi
    fi
}

function read_fluxo_branches_file {
    local FLUXO_BRANCH_NAME="$1"
    local FILE_NAME="_fluxo_branches"
  
    local fluxo_branches_from_file
    
    if ! fluxo_branches_from_file="$(read_fluxo_file "$FILE_NAME" "$FLUXO_BRANCH_NAME")"; then
        echo
		echo "$(view_errorline)$(view_errordot)$(tput bold) No $(tput sgr0 && tput smso) $FILE_NAME $(tput rmso && tput bold) file found. Aborting!$(tput sgr0)"
		echo "$(view_errorline)$(view_errordot) There must be a file named $(tput smso) $FILE_NAME $(tput sgr0) in a branch $(tput smso) $FLUXO_BRANCH_NAME $(tput sgr0) where all fluxo branches are listed ordered per line"
        return 1
    elif [ -z "$fluxo_branches_from_file" ]; then
        echo  
        echo "$(view_errorline)$(view_errordot)$(tput bold) Empty $(tput sgr0 && tput smso) $FILE_NAME $(tput rmso && tput bold) file. Aborting!$(tput sgr0)"
        echo "$(view_errorline)$(view_errordot) There must be a file named $(tput smso) $FILE_NAME $(tput sgr0) in a branch called $(tput smso) $FLUXO_BRANCH_NAME $(tput sgr0) where all fluxo branches are listed ordered per line"
        return 1
    fi

    printf '%s' "$fluxo_branches_from_file"
}
