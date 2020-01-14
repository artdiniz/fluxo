function read_fluxo_file {
    local FILE_NAME="$1"
    local FLUXO_BRANCH_NAME="$2"

    local _result_var_name="$3"

    if git show "$FLUXO_BRANCH_NAME":"$FILE_NAME" &> /dev/null; then
        eval "$_result_var_name=\"\$(git show "$FLUXO_BRANCH_NAME":"$FILE_NAME")\""
    else
        return 1
    fi
}

function read_fluxo_file_with_cache {
    local FILE_NAME="$1"
    local FLUXO_BRANCH_NAME="$2"

    local _result_var_name="$3"

    local cache_var_name="read_fluxo_file_cache_$FILE_NAME"
    local cache_file_content="${!cache_var_name}"

    if [ ! -z "$cache_file_content" ]; then
        eval "$_result_var_name=\$cache_file_content"
    else
        local file_content

        if _lib_run read_fluxo_file "$FILE_NAME" "$FLUXO_BRANCH_NAME" file_content && [ ! -z "$file_content" ]; then
            eval "$cache_var_name=\$file_content"
            eval "$_result_var_name=\$file_content"
        else
            return 1
        fi
    fi
}

function read_fluxo_branches_file {
    local FLUXO_BRANCH_NAME="$1"
    local FILE_NAME="_fluxo_branches"
  
    local fluxo_branches_from_file
    
    if ! _lib_run read_fluxo_file "$FILE_NAME" "$FLUXO_BRANCH_NAME" fluxo_branches_from_file; then
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
