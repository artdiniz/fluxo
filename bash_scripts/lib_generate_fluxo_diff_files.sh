#!/bin/bash -e

. $(cd "$(dirname "$0")" && pwd)"/lib_style.sh"

function printBranchesOrderedByFluxo {
    echo -en "$branches" |
    xargs -I {} echo {} |
    grep -v doing |
    grep -v "gh-pages" 
}

function read_fluxo_ignore {
    local FILE_NAME=".fluxoignore"
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
    color_setup

    PROJECT_DIR="$(pwd)"

    branches="$(show_fluxo --existent --raw)"

    local ignore_files="$(read_fluxo_ignore)"

    local exclude_git_dif_args="$(echo -e "$ignore_files" | xargs -I %% echo "\"':(exclude)$PROJECT_DIR/%%'\"" | tr '\n' ' ')"

    status="$?"
    if [ $status != 0 ]; then
        echo -e "$branches\n"
        exit $status
    fi

    TMP_FOLDER=mktemp

    rm -r "$TMP_FOLDER" 2> /dev/null
    mkdir -p "$TMP_FOLDER"
    cd $TMP_FOLDER

    printBranchesOrderedByFluxo |
    awk -v exclude_git_dif_args="$exclude_git_dif_args" '{OFS="";}NR>1{print "git diff " "\\\47"last"\\\47..\\\47"$1 "\\\47 " exclude_git_dif_args " >> " "\\\47"$1".diff\\\47" "\n"} {last=$1}' |
    xargs -I diffAndCreateFileCommmand bash -c "diffAndCreateFileCommmand"

    numberOfFiles=$(printBranchesOrderedByFluxo | grep -v master | wc -l | xargs)
    digits="${#numberOfFiles}"

    printBranchesOrderedByFluxo |
    grep -v master |
    awk -v digits="$digits" '{print $1".diff"," ",sprintf("%0"digits"d",NR-1)"-"$1".diff"}' |
    xargs -L1 mv 

    cd -

    [ -z "$1" ] && DEST_FOLDER="_fluxo_diff_files" || DEST_FOLDER=$1

    rm -r "$DEST_FOLDER" 2> /dev/null
    mkdir -p $DEST_FOLDER
    mv $TMP_FOLDER/* $DEST_FOLDER
    rm -r $TMP_FOLDER

    echo
    echo -e "Created $(style $BOLD$PURPLE $numberOfFiles) diff files in $(style $UNDERLINE$CYAN `pwd $DEST_FOLDER`/$DEST_FOLDER/)"
    echo

    ls $DEST_FOLDER | xargs -I {} bash -c "echo -ne \"    $(style $GREEN "•") $(style $GREY {})\n\""
    echo
}