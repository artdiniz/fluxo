#!/usr/bin/env bash

_HELP_TITLE="FLUXO-SHOW"

_HELP_USAGE="\
  show
  show [--existent | --unknown | --unexistent | --drafts] 
  show [--format=<format-options>] | [--format '<format-options>'] 
  show [-v | --verbose] 
  show [--raw]
"

_HELP_OPTIONS="\
  --format=<format-options>                    <format-options> pattern passed to \`git for-each-ref\`;
  -v|--verbose                                 show info about remotes and unknown branches (branches that are not in fluxo);
  --existent|--unknown|--unexistent|--drafts   choose which kind of fluxo branches to show. Default is showing all of them;
  --raw                                        remove all titles and decoration from output. Perfect for piping and processing in ohter programs;
"

_HELP_PARAMS=""

_HELP_OTHER="\
$(tput bold)SAMPLE COMMANDS$(tput sgr0)

  - Shows last commit short hash before branch name:
      fluxo show --format=\"%(color:cyan) %(objectname:short) %(color:reset) %(refname:short)\"

  - Shows list of full hashes for each branch HEAD commit
      fluxo show --format=\"%(objectname)\"
"

function get_branches_details {
	local branches="$1"
  local branches_details="$(printf '%b\n' "$branches" | xargs -I %% echo 'git branch -v | xargs -I [] echo "X=\"[]\" && printf '%b\n' \"\${X##\\* }\" | grep -w \"^%%\"" | bash -  | sed "s/^%% //"' | bash -)"
  printf '%b\n' "$branches_details"
}

function render_formatted_branches {
  local branches="$1" 
  local formatted_branches="$2" 
  local verbose="$3"

  if [ $verbose -eq 0 ]; then
    printf '%b\n' "$formatted_branches"
  else
    IFS=$'\n' branches_name_length=($(printf '%b\n' "$branches" | xargs -I %% bash -c 'X="%%" && printf '%b\n' "${#X}"'))

    local max_branch_name_length=0
    for i in "${branches_name_length[@]}"; do
      if [ $i -gt $max_branch_name_length ]; then
        local max_branch_name_length="$i"
      fi
    done

    IFS=$'\n' branches_name_padding=$(
      printf '%b\n' "$branches" | 
      xargs -I %% bash -c 'X="%%" && printf '%b\n' "${#X}"' | 
      xargs -I %% bash -c "X='%%' && echo \$(($max_branch_name_length - %%))"
    )
    # gets branches an concats with formatted branches names
    local qt_branches="$(count "$branches")"
    local branches_details="$(get_branches_details "$branches")"

    for i in $(seq 1 "$qt_branches"); do

      printf '%b' "$(printf '%b\n' "$formatted_branches" | head -n +$i | tail -n1)"

      local padding_spaces=$(printf '%b\n' "$branches_name_padding" | head -n +$i | tail -n1)
      for j in $(seq 1 "$(($padding_spaces + 1))"); do
        printf '%s' " "
      done

      printf '%b' "$(printf '%b\n' "$branches_details" | head -n +$i | tail -n1)"
      echo
    done
  fi
}

function render_branches_with_title {
  local title="$1"
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
      printf '%b\n' "$(render_formatted_branches "$branches" "$formatted_branches" "$verbose")"
    else
      local digits="${#number_of_branches}"

      local counted_and_formatted_branches="$(
        printf '%b\n' "$formatted_branches" |
        awk -F'\n' -v color="$color" -v color_reset="$(tput sgr0)" -v digits="$digits" '{gsub("#color", color, $1); gsub("#rcolor", color_reset, $1); gsub("#dd", sprintf("%0"digits"d",NR-1) , $1); print $1}'
      )"

      printf '%b\n' "$title"

      printf '%b\n' "$(render_formatted_branches "$branches" "$counted_and_formatted_branches" "$verbose")"
    fi
	fi
}

function render_branches_color {
  [ -x $1 ] && echo "$(tput setaf 6)" || echo "$1"
}

function render_branches_title {
  local branches_group_name="$1"
  local branches="$2"
  local color="$(render_branches_color "$3")"

  local number_of_branches="$(count "$branches")"
  [ "$number_of_branches" -eq 1 ] && local pluralized_branch_word="branch" || local pluralized_branch_word="branches"

  printf '%b\n' "$(tput smul)$(tput bold)$color$number_of_branches $branches_group_name$(tput rmul) $pluralized_branch_word$(tput sgr0)"
}

function render_branches {
  local branches_group_name="$1"
  local branches="$2"
  local format="$3"
  local verbose="$4"
  local raw="$5"
  local color="$(render_branches_color "$6")"

  local title="$(render_branches_title "$branches_group_name" "$branches" "$color")\\n"
  render_branches_with_title "$title" "$branches" "$format" "$verbose" "$raw" "$color"
}

function show_fluxo {
  _parse_help_args "$@"

  local verbose=0
  local raw=0

  local show_types=""

  local format

  total_argc=$#
  while test $# -gt 0
  do
    case "$1" in
    -v|--verbose)
      verbose=1
      shift
    ;;
    --format*)
      local _possible_format_value="${1##--format}"
      if [ -z "$_possible_format_value" ]; then
        # Format value is passed without equals sign --format format-value
        shift
        local _possible_format_value="$1"
        if [ -z "$_possible_format_value" ]; then 
          # Error: no format value provided
          #   fluxo show ... --format 
          #   fluxo show ... --format "" ...
          _lib_run _help_print_usage_error_and_die "Empty '--format' value"
        fi
        format="$_possible_format_value"
      else
        # Format is passed with equals sign --format="format-value"
        format="${_possible_format_value##=}"
      fi
      shift
    ;;
    --existent|--unknown|--unexistent|--drafts)
      [ ${1##--} == 'existent' ] && local type="ex"
      [ ${1##--} == 'unknown' ] && local type="unk"
      [ ${1##--} == 'unexistent' ] && local type="unx"
      [ ${1##--} == 'drafts' ] && local type="dft"

      local show_types="${type##--} $show_types"

      if [ ! -z "$2" ] && [ "${2##--}" == "$2" ]; then
        local from_branch_arg="$2"
      fi

      shift
    ;;
    --raw)
      local raw=1
      shift
    ;;
    *)
      _lib_run _help_print_usage_error_and_die "Invalid option: '$1'"
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
  local show_drafts="$(has "$show_types" dft)"

	
  if [ $show_unexistent -eq 1 ]; then
    local unexistent_fluxo_branches

    unexistent_fluxo_branches="$(_lib_run get_unexistent_fluxo_branches)"
    
    if test $? -eq 1; then
      printf '%b\n' "$unexistent_fluxo_branches"
      exit 1
    fi

    local number_of_unexistent_fluxo_branches
    number_of_unexistent_fluxo_branches="$(_lib_run count "$unexistent_fluxo_branches")"
    
    if [ "$number_of_unexistent_fluxo_branches" -gt 0 ]; then
      if [ $raw -eq 0 ]; then
        local unexistent_view="$(
          printf '%b\n' "$(view_errorline 'WARNING') $(($number_of_unexistent_fluxo_branches)) unexistent branches present in \`_fluxo_branches\` file:"
          echo
          printf '%b\n' "$unexistent_fluxo_branches" | xargs -I {} echo "$(tput setaf 1 && tput bold)•$(tput sgr0) {}"
          echo
          printf '%b\n' "$(view_errorline 'WARNING') Their names may be mispelled or those branches are not created nor pulled from remote yet."
        )"
      else
        local unexistent_view="$(printf '%b\n' "$unexistent_fluxo_branches")"
      fi
    fi
  fi

  if [ $show_existent -eq 1 ]; then
    local existent_branches
    existent_branches="$(_lib_run get_existent_fluxo_branches)"

    if test $? -eq 1; then
      printf '%b\n' "$existent_branches"
      exit 1
    fi

    local existent_view="$(render_branches "fluxo" "$existent_branches" "$format" "$verbose" "$raw")"
  fi

  if [ $show_unknow -eq 1 ]; then 
    local unknown_to_fluxo_branches
    unknown_to_fluxo_branches="$(_lib_run get_unknown_branches)"

    if test $? -eq 1; then
      printf '%b\n' "$unknown_to_fluxo_branches"
      exit 1
    fi

    local unknown_to_fluxo_view="$(render_branches "unknown" "$unknown_to_fluxo_branches" "$format" "$verbose" "$raw" "$(tput setaf 5)")"
  fi

  if [ $show_drafts -eq 1 ]; then
    local known_branches
    known_branches="$(_lib_run get_existent_fluxo_branches)"

    if test $? -eq 1; then
      printf '%b\n' "$known_branches"
      exit 1
    fi

    local unknown_to_fluxo_branches="$(_lib_run get_unknown_branches)"

    if [ -n "$from_branch_arg" ] && [ -z "$(_lib_run filter_branches_in "$known_branches" "$from_branch_arg")" ]; then
      [ $raw -eq 0 ] && printf '%b\n' "Can't show drafts from '$from_branch_arg', because there isn't a fluxo branch named '$from_branch_arg'"
      exit 1
    fi

    IFS=$'\n'; known_branches=($known_branches); unset IFS;
    
    local drafts_view="$(
      local all_draft_branches=""
      local known_branches_length=${#known_branches[@]}
      local drafts_view_inverted=""

      local digits="${#known_branches_length}"

      for (( loop_index=$known_branches_length ; loop_index>0 ; loop_index-- )) ; do
          local branch_position="$(( loop_index - 1 ))"
          local fluxo_branch="${known_branches[branch_position]}"
          local fluxo_branch_children="$(git branch --format="%(refname:short)" --sort="committerdate" --contains "$fluxo_branch" | grep -v -wE "^$fluxo_branch$")"

          local ordered_draft_branches="$(filter_branches_in "$unknown_to_fluxo_branches" "$fluxo_branch_children")"

          local padded_branch_position="$(printf %0"$digits"d $branch_position)"
          
          if [ -n "$ordered_draft_branches" ]; then
            [ $loop_index -lt $known_branches_length ] && all_draft_branches+="\\n"
            all_draft_branches+="${ordered_draft_branches##\\n}"
            all_draft_branches="${all_draft_branches##\\n}"
            all_draft_branches="${all_draft_branches%%\\n}"

            unknown_to_fluxo_branches="$(filter_branches_not_in "$unknown_to_fluxo_branches" "$all_draft_branches")"
            
            local number_of_branches="$(count "$ordered_draft_branches")"
            [ "$number_of_branches" -eq 1 ] && local pluralized_branch_word="branch" || local pluralized_branch_word="branches"
            local draft_title="\033[38;5;242mfrom$(tput sgr0)$(tput setaf 5) $padded_branch_position| $(tput bold)$fluxo_branch$(tput sgr0)\033[38;5;242m – $number_of_branches draft $pluralized_branch_word $(tput sgr0)"
            draft_title+="\\n      \033[38;5;242m|$(tput sgr0)"

            [ $raw -eq 1 ] && local format="%(refname:short)" || local format="   %(if)%(HEAD)%(then) * #color|–—–—#rcolor $(tput bold)%(color:green)%(refname:short)%(else)  \033[38;5;242m |–—–—$(tput sgr0) %(refname:short)%(end)"

            local view="$(render_branches_with_title "$draft_title" "$ordered_draft_branches" "$format" "$verbose" "$raw" "$(tput setaf 6)")"
            local inverted_view="$(echo "$view" | awk '{a[i++]=$0} END {for (j=i-1; j>=0;) print a[j--] }')"

            drafts_view_inverted+="\n$inverted_view\n"
            if [ "$from_branch_arg" == "$fluxo_branch" ]; then
              all_draft_branches="$ordered_draft_branches"
              drafts_view_inverted="\n$inverted_view\n"
              break
            fi
          elif [ "$from_branch_arg" == "$fluxo_branch" ]; then
            all_draft_branches=""
            [ $raw -eq 1 ] && drafts_view_inverted="" || drafts_view_inverted="No drafts from $fluxo_branch"
            break
          fi

          if [ -z "$unknown_to_fluxo_branches" ]; then
            echo "$unknown_to_fluxo_branches"
            break
          fi
      done

      if [ -n "$all_draft_branches" ]; then
        local drafts_view_body="$(printf '%b\n' "${drafts_view_inverted%%\\n}" | awk '{a[i++]=$0} END {for (j=i-1; j>=0;) print a[j--] }')"
      elif [ -z "$from_branch_arg" ]; then
        [ $raw -eq 0 ] && local drafts_view_body="No draft branches anywhere"
      fi
      
      if [ $raw -eq 1 ]; then
        printf '%b\n' "$drafts_view_body"
      else
        local drafts_view_title="$(render_branches_title "draft" "$all_draft_branches" $(tput setaf 5))"
        printf '%b\n' "$drafts_view_title\\n\\n$(printf '%b\n' "$drafts_view_body" | sed 's/^/   /')"
      fi
    )"
  fi

  local view="$(_lib_run view_join "$unexistent_view" "$existent_view" "$unknown_to_fluxo_view" "$drafts_view")"
  
  if [ $raw -eq 1 ]; then
    if [ "$(count "$view")" -gt 0 ]; then
      printf '%b\n' "$view" | less -XRF
    fi
  else
    echo
    printf '%b\n' "$view" | less -XRF
    echo
  fi
}
