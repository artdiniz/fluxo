#!/bin/bash -e

. $(cd "$(dirname "$0")" && pwd)"/lib_style.sh"

function printBranchesOrderedByFluxo {
    echo -en "$branches" |
    xargs -I {} echo {} |
    grep -v doing |
    grep -v "gh-pages" 
}

function generate_fluxo_diff_files {
    color_setup

    branches="$(show_fluxo_raw)"

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
    awk '{OFS="";}NR>1{print "git diff " "\\\47"last"\\\47..\\\47"$1 "\\\47 >> " "\\\47"$1".diff\\\47" "\n"} {last=$1}' |
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