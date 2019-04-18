#!/bin/bash -e

FLUXO_SHOW_HELP_MESSAGE="\
GIT-FLUXOSHOW

$(tput bold)USAGE$(tput sgr0)

  git fluxo show
  git fluxo show --format=<format-options> | [-v | --verbose]

$(tput bold)ACTIONS$(tput sgr0)

  --help                         show detailed instructions
  --format=<format-options>      <format-options> pattern passed to \`git for-each-ref\`
  -v|--verbose                   show info about remotes and unknown branches (branches that are not in fluxo)

$(tput bold)SAMPLE COMMANDS$(tput sgr0)

  - Shows last commit short hash before branch name:
      git fls --format=\"%(color:cyan) %(objectname:short) %(color:reset) %(refname:short)\"

  - Shows list of full hashes for each branch HEAD commit
      git fls --format=\"%(objectname)\"
"

function errorline {
	[ -z "$1" ] && local text="Error " || local text="$1"
	echo -e "$(tput setaf 7)$(tput setab 1)$(tput bold) $text $(tput sgr0) "
}

function errordot {
	echo -e "$(tput setaf 1 && tput bold)•$(tput sgr0)"
}

function read_branches_file {
  local PROJECT_DIR=$(echo `pwd`)
  local FILE_NAME="_fluxo_branches"

	local FILE_PATH="$PROJECT_DIR/$FILE_NAME"

  if [ -e "$PROJECT_DIR/$FILE_NAME" ]; then
		cat "$FILE_PATH"
  else
		
		echo
		echo "$(errorline)$(errordot)$(tput bold) No $(tput sgr0 && tput smso) $FILE_NAME $(tput rmso && tput bold) file found. Aborting!$(tput sgr0)"
		echo "$(errorline)$(errordot) There must be a file named $(tput smso) $FILE_NAME $(tput sgr0) where all fluxo branches are listed ordered per line"
		exit 1
  fi
}

function print_formatted_branches {
		branches=$1
		git_for_each_ref_args="${@:2}"

		formattedBranches="$(
			echo -ne "$branches" |
			xargs -I {} echo "git for-each-ref $(echo -e "$git_for_each_ref_args") --color=always 'refs/heads/{}'" | 
			bash -
		)"

		echo -e "${formattedBranches%"\n"}"
}

function get_unknown_branches {
	local fluxo_branches_from_file="$1"

	local all_branches=$(git br --format="%(refname:short)")
  local fluxo_branches_for_grep=$(echo -e "$fluxo_branches_from_file" | tr '\n' '|')
	local branches="$(echo -e "$all_branches" | grep -v -E "${fluxo_branches_for_grep%|}")"
	echo -e "$branches"
}

function get_unexistent_fluxo_branches {
	local fluxo_branches_from_file="$1"

  local existentBranchesGrepArg=$(git br --format="%(refname:short)" | tr '\n' '|')
	local branches="$(echo -e "$fluxo_branches_from_file" | grep -v -E "${existentBranchesGrepArg%|}")"
	echo -e "$branches"
}

function get_existent_fluxo_branches {
	local fluxo_branches_from_file="$1"

  local existentBranchesGrepArg=$(git br --format="%(refname:short)" | tr '\n' '|')
	local branches="$(echo -e "$fluxo_branches_from_file" | grep -E "${existentBranchesGrepArg%|}")"
	echo -e "$branches"
}

function print_fluxo_show_usage_and_die {
  echo "Invalid arguments: $@"
  echo -e "\n$FLUXO_SHOW_HELP_MESSAGE\n"
  exit $?
}

function print_fluxo_show_usage {
  echo -e "\n$FLUXO_SHOW_HELP_MESSAGE\n"
}

function asVerbose {
	local branches="$1"
	echo -e "$branches" | xargs -I {} bash -c "git br -v --color=always | grep --color=never {}"
}

function count {
	local to_be_counted="$1"
	local line_count="$(echo -ne "$to_be_counted" | wc -l | xargs)"
	[ "$to_be_counted" == '' ] && local count=0 || local count=$(($line_count + 1))
	echo "$count"
}

function render_branches {
  local branches_title="$1"
  local branches="$2"
  local format="$3"
  local verbose="$4"
  [ -x $5 ] && local color="$(tput setaf 6)" || local color="$5"

  local formatted_branches="$(print_formatted_branches "$branches" --format=\""$format"\")"
  local number_of_branches="$(count "$branches")"

  local digits="${#number_of_branches}"

  local counted_and_formatted_branches="$(
    echo -e "$formatted_branches" |
    awk -F'\n' -v color="$color" -v color_reset="$(tput sgr0)" -v digits="$digits" '{gsub("#color", color, $1); gsub("#rcolor", color_reset, $1); gsub("#dd", sprintf("%0"digits"d",NR-1) , $1); print $1}'
  )"

	if [ "$number_of_branches" -gt 0 ]; then
    [ "$number_of_branches" -eq 1 ] && local pluralized_branch_word="branch" || local pluralized_branch_word="branches"
		echo
		echo "$(tput smul)$(tput bold)$color$number_of_branches $branches_title$(tput rmul) $pluralized_branch_word$(tput sgr0)"
		echo
		[ $verbose -eq 1 ] && asVerbose "$branches" || echo -e "$counted_and_formatted_branches"
	fi
}

function show_fluxo {
  local format="%(if)%(HEAD)%(then) * #color#dd|#rcolor $(tput bold)%(color:green)%(refname:short)%(else)  \033[38;5;242m #dd|$(tput sgr0) %(refname:short)%(end)"
  local verbose=0

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

	fluxo_branches_from_file="$(read_branches_file)"
	if [ $? != 0 ]; then 
    echo -e "$fluxo_branches_from_file\n"
    exit $?
  fi

	local existent_branches="$(get_existent_fluxo_branches "$fluxo_branches_from_file")"
	local unknown_to_fluxo_branches="$(get_unknown_branches "$fluxo_branches_from_file")"
	local unexistent_fluxo_branches="$(get_unexistent_fluxo_branches "$fluxo_branches_from_file")"
  
	local number_of_unexistent_fluxo_branches="$(count "$unexistent_fluxo_branches")"
	
	if [ "$number_of_unexistent_fluxo_branches" -gt 0 ]; then
		echo
		echo -e "$(errorline 'WARNING') $(($number_of_unexistent_fluxo_branches)) unexistent branches present in \`_fluxo_branches\` file:"
		echo
		echo -e "$unexistent_fluxo_branches" | xargs -I {} echo "$(tput setaf 1 && tput bold)•$(tput sgr0) {}"
		echo
		echo -e "$(errorline 'WARNING') Their names may be mispelled or those branches are not created nor pulled from remote yet."
    echo
	fi

  view="$(
    render_branches "fluxo" "$existent_branches" "$format" "$verbose" &&
    echo
    render_branches "unknown" "$unknown_to_fluxo_branches" "$format" "$verbose" "$(tput setaf 5)" 
  )"

  echo -e "$view"

	echo
}

function show_fluxo_raw {
  local fluxo_branches_from_file="$(read_branches_file)"
	if [ $? != 0 ]; then 
    echo -e "$fluxo_branches_from_file\n"
    exit $?
  fi

	local existent_branches=$(get_existent_fluxo_branches "$fluxo_branches_from_file")
	print_formatted_branches "$existent_branches" --format=\""%(refname:short)\""
}