#!/bin/bash -e

FLUXO_SHOW_HELP_MESSAGE="\
GIT-FLUXOSHOW

$(tput bold)USAGE$(tput sgr0)

  git fluxo show
  git fluxo show --format=<format-options> | [-v | --verbose]

$(tput bold)ACTIONS$(tput sgr0)

  --help                         show detailed instructions
  --format=<format-options>      <format-options> pattern passed to \`git for-each-ref\`
  -v|--verbose                   show info about remotes

$(tput bold)PARAMS$(tput sgr0)

  <a-branch-da-aula-que-teve-mudancas> A branch que foi modificada com novos commits
  <a-branch-da-proxima-aula> é a branch da aula seguinte à que foi modificada, caso a branch aula1 tenha sido modificada, é a branch da aula 2
"

function show_fluxo_branches {
    PROJECT_DIR=$(echo `pwd`)
    FILE_NAME="_fluxo_branches"

    if [ -e "$PROJECT_DIR/$FILE_NAME" ]; then
        branchesGrepArg=$(git br --format="%(refname:short)" | tr '\n' '|')
        branches=$(grep -E "${branchesGrepArg%|}" $FILE_NAME)
        
        formattedBranches=$(
            echo -ne "$branches" |
            xargs -I {} git for-each-ref "$@" --color=always "refs/heads/{}"
        )

        echo -e "${formattedBranches%"\n"}"
    else
        echo
        echo "$(errorline)$(tput bold) No $(tput sgr0 && tput smso) $FILE_NAME $(tput rmso && tput bold) file found. Aborting!$(tput sgr0)"
        echo "$(errorline) There must be a file named $FILE_NAME where all fluxo branches are listed ordered per line"
        echo
        exit 1
    fi
}



function errorline {
    echo -ne "$(tput setaf 7)$(tput setab 1)$(tput bold) Error $(tput sgr0) $(tput setaf 1)$(tput bold)•$(tput sgr0)"
}

function print_fluxo_show_usage_and_die {
  echo -ne "\n$FLUXO_SHOW_HELP_MESSAGE\n"
  exit $?
}

function print_fluxo_show_usage {
  echo -ne "\n$FLUXO_SHOW_HELP_MESSAGE"
}

function show_fluxo {
    if [ $# == 0 ]; then
        show_fluxo_branches --format="%(if)%(HEAD)%(then)* %(color:green)%(else)  %(end)%(refname:short)"
    elif [ $# == 1 ]; then
        case "$1" in
        -v|--verbose)
            show_fluxo_branches --format="%(refname:short)" | xargs -I {} bash -c "git br -v --color=always | grep --color=never {}"
            exit $?
        ;;
        --format*)
            show_fluxo_branches $1
            exit
        ;;
        -h|--help)
            print_fluxo_show_usage | less -RF
            exit $?
        ;;
        *)
            print_fluxo_show_usage_and_die
        ;;
        esac
    elif [ $# > 1 ]; then
        print_fluxo_show_usage_and_die
    fi
}

function show_fluxo_raw {
    show_fluxo_branches --format="%(refname:short)" "$@"
}