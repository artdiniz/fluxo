_HELP_TITLE="FLUXO"

_HELP_USAGE="\
  $_FLUXO_COMMAND_NAME <show | diff | rebase | doctor>
  $_FLUXO_COMMAND_NAME <-h|--help>
"

_HELP_DETAILS="\
$(tput bold)ACTIONS$(tput sgr0)

  -h | --help      Show detailed instructions

$(tput bold)FLUXO COMMANDS$(tput sgr0)

  <show | s>           Show branches ordered by fluxo steps
  <diff | d>           Generate code diff files for each fluxo step
  <rebase | r>         Rebase after changing any fluxo previous steps
  <doctor | dr>        Check fluxo project health (Are steps synchronized?)
"

navigate_to_git_repository_root

case "$1" in
-h|--help)
	_lib_run _help_print_full_message
	exit $?
	;;
show|s)
	shift
	. "$_FLUXO_SCRIPTS_DIR/cmd_show_fluxo.sh"
	_lib_run show_fluxo "$@"
	;;
drafts|dt)
	. "$_FLUXO_SCRIPTS_DIR/cmd_show_fluxo.sh"
	shift
	_lib_run show_fluxo --drafts "$@"
	;;
diff|d)
	shift
	. "$_FLUXO_SCRIPTS_DIR/cmd_generate_fluxo_diff_files.sh"
	_lib_run generate_fluxo_diff_files "$@"
	;;
rebase|r)
	shift
	. "$_FLUXO_SCRIPTS_DIR/cmd_rebase_fluxo.sh"
	_lib_run rebase_fluxo "$@"
	;;
doctor|dr)
	shift
	. "$_FLUXO_SCRIPTS_DIR/cmd_fluxo_doctor.sh"
	_lib_run fluxo_doctor "$@"
	;;
*)
	_lib_run _help_print_usage_error_and_die "$_FLUXO_COMMAND"
	;;
esac
