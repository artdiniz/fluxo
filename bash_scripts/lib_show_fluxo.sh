#!/bin/bash -e

function show_fluxo {
    branches=$(show_fluxo_raw $1)
    
    CURRENT_BRANCH=$(git br | grep '\*' | head -n 1 | sed -e 's/[\* ]//g')
    
    formattedBranches=$(
        echo -ne "$branches" |
        xargs -I {} bash -c "echo -ne \"  {}\n\"" |
        sed "s/  $CURRENT_BRANCH/* $(tput setaf 2)$CURRENT_BRANCH$(tput sgr0)/"
    )

    echo
    echo -ne "${formattedBranches}"
    echo
    echo
}

function errorline {
    echo -ne "$(tput setaf 7)$(tput setab 1)$(tput bold) Error $(tput sgr0) $(tput setaf 1)$(tput bold)•$(tput sgr0)"
}

function show_fluxo_raw {
    PROJECT_DIR=$(echo `pwd`)
    FILE_NAME="_fluxo_branches"

    if [ -e "$PROJECT_DIR/$FILE_NAME" ]; then
        branchesGrepArg=$(git br --format="%(refname:short)" | tr '\n' '|')
        branches=$(grep -E "${branchesGrepArg%|}" $FILE_NAME)
        formattedBranches=$(
            echo -ne "$branches" |
            xargs -I {} bash -c "echo -ne \"{}\n\""
            # xargs -I {} git for-each-ref --format="%(refname:short)" refs/heads/{} |
        )
        
        echo -ne "${formattedBranches%"\n"}"
        echo
    else
        echo
        echo "$(errorline)$(tput bold) No $(tput sgr0 && tput smso) $FILE_NAME $(tput rmso && tput bold) file found. Aborting!$(tput sgr0)"
        echo "$(errorline) There must be a file named $FILE_NAME where all fluxo branches are listed ordered per line"
        echo
        exit 1
    fi
}