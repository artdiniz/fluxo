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
"

function show_fluxo_branches {
    PROJECT_DIR=$(echo `pwd`)
    FILE_NAME="_fluxo_branches"

    if [ -e "$PROJECT_DIR/$FILE_NAME" ]; then
        branchesGrepArg=$(git br --format="%(refname:short)" | tr '\n' '|')
        branches=$(grep -E "${branchesGrepArg%|}" $FILE_NAME)
        
        formattedBranches="$(
            echo -ne "$branches" |
            xargs -I {} echo "git for-each-ref $(echo -e "$@") --color=always 'refs/heads/{}'" | 
            bash -
        )"

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
  echo "Invalid arguments: $@"
  echo -e "\n$FLUXO_SHOW_HELP_MESSAGE\n"
  exit $?
}

function print_fluxo_show_usage {
  echo -e "\n$FLUXO_SHOW_HELP_MESSAGE"
}

function show_fluxo {
  format="%(if)%(HEAD)%(then)* %(color:green)%(else)  %(end)%(refname:short)"
  verbose=0

  total_argc=$#
  while test $# -gt 0
  do
    case "$1" in
    show)
      shift
    ;;
    --)
      shift
    ;;
    -h|--help)
      print_fluxo_show_usage | less -XR
      clear
      exit $?
    ;;
    -v|--verbose)
      format="%(refname:short)"
      verbose=1
      break
    ;;
    --format*)
      format="${1##--format}"
      shift
      if [ -z "$format" ]; then
          if [ -z "$1" ]; then 
              print_fluxo_show_usage_and_die "$@"
          elif [ "${1##-}" == "$1" ]; then
              format="$1"
          else
              print_fluxo_show_usage_and_die "$@"
          fi
      else
          format="${format##=}"
      fi
      shift
    ;;
    *)
      print_fluxo_show_usage_and_die "$@"
    ;;
    esac
  done

  b="$(show_fluxo_branches --format=\""$format"\")"
  
  if [ $verbose -eq 1 ]; then
    echo -e "$b" | xargs -I {} bash -c "git br -v --color=always | grep --color=never {}"
  else
    echo -e "$b"
  fi
}

function show_fluxo_raw {
    show_fluxo_branches --format=\""%(refname:short)\"" "$@"
}