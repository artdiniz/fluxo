#!/bin/bash -e

FLUXO_SHOW_HELP_MESSAGE="\
GIT-FLUXOSHOW

$(tput bold)USAGE$(tput sgr0)

  git fluxo show
  git fluxo show --format=<format-options> | [-v | --verbose]

$(tput bold)ACTIONS$(tput sgr0)

  --help                                   show detailed instructions
  --format=<format-options>                <format-options> pattern passed to \`git for-each-ref\`;
  -v|--verbose                             show info about remotes and unknown branches (branches that are not in fluxo);
  --existent|--unknown|--unexistent        choose which kind of fluxo branches to show. Default is showing all of them;
  --raw                                    remove all titles and decoration from output. Perfect for piping and processing in ohter programs;

$(tput bold)SAMPLE COMMANDS$(tput sgr0)

  - Shows last commit short hash before branch name:
      git fls --format=\"%(color:cyan) %(objectname:short) %(color:reset) %(refname:short)\"

  - Shows list of full hashes for each branch HEAD commit
      git fls --format=\"%(objectname)\"
"

function read_ignore_branches_file {
  local FILE_NAME="_fluxo_branches_ignore "
  local FLUXO_BRANCH_NAME="_fluxo"
  
  git show "$FLUXO_BRANCH_NAME":"$FILE_NAME" &> /dev/null
  local status=$?

  if [ $status != 0 ]; then
    exit
  else
    local branches_file_content="$(git show $FLUXO_BRANCH_NAME:$FILE_NAME)"
    if [ -z "$branches_file_content" ]; then
      exit
    else
      echo -e "$branches_file_content"
    fi
  fi
}

function read_branches_file {
  local FILE_NAME="_fluxo_branches"
  local FLUXO_BRANCH_NAME="_fluxo"
  
  git show "$FLUXO_BRANCH_NAME":"$FILE_NAME" &> /dev/null
  local status=$?

  if [ $status != 0 ]; then
    echo
		echo "$(view_errorline)$(view_errordot)$(tput bold) No $(tput sgr0 && tput smso) $FILE_NAME $(tput rmso && tput bold) file found. Aborting!$(tput sgr0)"
		echo "$(view_errorline)$(view_errordot) There must be a file named $(tput smso) $FILE_NAME $(tput sgr0) in a branch $(tput smso) $FLUXO_BRANCH_NAME $(tput sgr0) where all fluxo branches are listed ordered per line"
		exit 1
  else
    local branches_file_content="$(git show $FLUXO_BRANCH_NAME:$FILE_NAME)"
    if [ -z "$branches_file_content" ]; then
      echo
      echo "$(view_errorline)$(view_errordot)$(tput bold) Empty $(tput sgr0 && tput smso) $FILE_NAME $(tput rmso && tput bold) file. Aborting!$(tput sgr0)"
      echo "$(view_errorline)$(view_errordot) There must be a file named $(tput smso) $FILE_NAME $(tput sgr0) in a branch called $(tput smso) $FLUXO_BRANCH_NAME $(tput sgr0) where all fluxo branches are listed ordered per line"
      exit 1
    else
      echo -e "$branches_file_content"
    fi
  fi
}

function print_fluxo_show_usage_and_die {
  echo "Invalid arguments: $@"
  echo -e "\n$FLUXO_SHOW_HELP_MESSAGE\n"
  exit 1
}

function print_fluxo_show_usage {
  echo -e "\n$FLUXO_SHOW_HELP_MESSAGE\n"
}

function get_branches_details {
	local branches="$1"
  local branches_details="$(echo -e "$branches" | xargs -I %% echo 'git br -v | xargs -I [] echo "X=\"[]\" && echo -e \"\${X##\\* }\" | grep -w \"^%%\"" | bash -  | sed "s/^%% //"' | bash -)"
  echo -e "$branches_details"
}

function render_formatted_branches {
  local branches="$1" 
  local formatted_branches="$2" 
  local verbose="$3"

  if [ $verbose -eq 0 ]; then
    echo -e "$formatted_branches"
  else
    IFS=$'\n' branches_name_length=($(echo -e "$branches" | xargs -I %% bash -c 'X="%%" && echo -e "${#X}"'))

    local max_branch_name_length=0
    for i in "${branches_name_length[@]}"; do
      if [ $i -gt $max_branch_name_length ]; then
        local max_branch_name_length="$i"
      fi
    done

    IFS=$'\n' branches_name_padding=$(
      echo -e "$branches" | 
      xargs -I %% bash -c 'X="%%" && echo -e "${#X}"' | 
      xargs -I %% bash -c "X='%%' && echo \$(($max_branch_name_length - %%))"
    )
    # gets branches an concats with formatted branches names
    local qt_branches="$(count "$branches")"
    local branches_details="$(get_branches_details "$branches")"

    for i in $(seq 1 "$qt_branches"); do

      echo -ne "$(echo -e "$formatted_branches" | head -n +$i | tail -n1)"

      local padding_spaces=$(echo -e "$branches_name_padding" | head -n +$i | tail -n1)
      for j in $(seq 1 "$(($padding_spaces + 1))"); do
        echo -n " "
      done

      echo -ne "$(echo -e "$branches_details" | head -n +$i | tail -n1)"
      echo
    done
  fi
}

function render_branches {
  local branches_title="$1"
  local branches="$2"
  local format="$3"
  local verbose="$4"
  local raw="$5"

  [ -x $6 ] && local color="$(tput setaf 6)" || local color="$6"

  if [ -z "$format" ]; then
    [ $raw -eq 1 ] && local format="%(refname:short)" || local format="%(if)%(HEAD)%(then) * #color#dd|#rcolor $(tput bold)%(color:green)%(refname:short)%(else)  \033[38;5;242m #dd|$(tput sgr0) %(refname:short)%(end)"
  fi

  local formatted_branches="$(view_git_for_each_ref "$branches" --format=\""$format"\")"
  local number_of_branches="$(count "$branches")"

	if [ "$number_of_branches" -gt 0 ]; then
    if [ $raw -eq 1 ]; then
      echo -e "$(render_formatted_branches "$branches" "$formatted_branches" "$verbose")"
    else
      local digits="${#number_of_branches}"

      local counted_and_formatted_branches="$(
        echo -e "$formatted_branches" |
        awk -F'\n' -v color="$color" -v color_reset="$(tput sgr0)" -v digits="$digits" '{gsub("#color", color, $1); gsub("#rcolor", color_reset, $1); gsub("#dd", sprintf("%0"digits"d",NR-1) , $1); print $1}'
      )"

      [ "$number_of_branches" -eq 1 ] && local pluralized_branch_word="branch" || local pluralized_branch_word="branches"
      echo "$(tput smul)$(tput bold)$color$number_of_branches $branches_title$(tput rmul) $pluralized_branch_word$(tput sgr0)"
      echo

      echo -e "$(render_formatted_branches "$branches" "$counted_and_formatted_branches" "$verbose")"
    fi
	fi
}

function show_fluxo {
  local verbose=0
  local raw=0

  local show_types=""

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
      print_fluxo_show_usage | less -XRF
      exit $?
    ;;
    -v|--verbose)
      local verbose=1
      shift
    ;;
    --format*)
      local format="${1##--format}"
      shift
      if [ -z "$format" ]; then
        if [ -z "$1" ]; then 
          print_fluxo_show_usage_and_die "$@"
        elif [ "${1##-}" == "$1" ]; then
          local format="$1"
        else
          print_fluxo_show_usage_and_die "$@"
        fi
      else
        local format="${format##=}"
      fi
      shift
    ;;
    --existent|--unknown|--unexistent)
      [ ${1##--} == 'existent' ] && local type="ex"
      [ ${1##--} == 'unknown' ] && local type="unk"
      [ ${1##--} == 'unexistent' ] && local type="unx"

      local show_types="${type##--} $show_types"

      shift
    ;;
    --raw)
      local raw=1
      shift
    ;;
    *)
      print_fluxo_show_usage_and_die "$@"
    ;;
    esac
  done
  
  local show_types=${show_types%%" "}
  if [ "$show_types" == '' ]; then 
    local show_types="ex unk unx"
  fi

  local show_existent="$(has "$show_types" ex)"
  local show_unknow="$(has "$show_types" unk)"
  local show_unexistent="$(has "$show_types" unx)"

	fluxo_branches_from_file="$(read_branches_file)"
	if [ $? != 0 ]; then 
    echo -e "$fluxo_branches_from_file\n"
    exit 1
  fi
	
  if [ $show_unexistent -eq 1 ]; then
    local unexistent_fluxo_branches="$(get_unexistent_fluxo_branches "$fluxo_branches_from_file")"

    local number_of_unexistent_fluxo_branches="$(count "$unexistent_fluxo_branches")"
    
    if [ "$number_of_unexistent_fluxo_branches" -gt 0 ]; then
      if [ $raw -eq 0 ]; then
        local unexistent_view="$(
          echo -e "$(view_errorline 'WARNING') $(($number_of_unexistent_fluxo_branches)) unexistent branches present in \`_fluxo_branches\` file:"
          echo
          echo -e "$unexistent_fluxo_branches" | xargs -I {} echo "$(tput setaf 1 && tput bold)•$(tput sgr0) {}"
          echo
          echo -e "$(view_errorline 'WARNING') Their names may be mispelled or those branches are not created nor pulled from remote yet."
        )"
      else
        local unexistent_view="$(echo -e "$unexistent_fluxo_branches")"
      fi
    fi
  fi

  if [ $show_existent -eq 1 ]; then
    local existent_branches="$(get_existent_fluxo_branches "$fluxo_branches_from_file")"
    local existent_view="$(render_branches "fluxo" "$existent_branches" "$format" "$verbose" "$raw")"
  fi

  if [ $show_unknow -eq 1 ]; then 
    local unknown_to_fluxo_branches="$(get_unknown_branches "$fluxo_branches_from_file")"
    local unknown_to_fluxo_view="$(render_branches "unknown" "$unknown_to_fluxo_branches" "$format" "$verbose" "$raw" "$(tput setaf 5)")"
  fi

  local view="$(view_join "$unexistent_view" "$existent_view" "$unknown_to_fluxo_view")"
  
  if [ $raw -eq 1 ]; then
    if [ "$(count "$view")" -gt 0 ]; then
      echo -e "$view" | less -XRF
    fi
  else
    echo
    echo -e "$view" | less -XRF
    echo
  fi
}
