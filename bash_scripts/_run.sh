_HELP_TITLE="FLUXO"

_HELP_USAGE="\
  <show | diff | checkout | rebase | doctor>
"

_HELP_PARAMS="\
  <show | s>           Show branches ordered by fluxo steps
  <diff | d>           Generate code diff files for each fluxo step
  <rebase | r>         Rebase after changing any fluxo previous steps
  <doctor | dr>        Check fluxo project health (Are steps synchronized?)
  <checkout | co>      Checkout fluxo step to \`_fluxo_steps\` folder
"

navigate_to_git_repository_root

_parse_help_args "$1"

case "$1" in
show|s)
	shift
	. "$_FLUXO_SCRIPTS_DIR/cmd_show_fluxo.sh"
	_lib_run _parse_help_args "$@"
	_lib_run show_fluxo "$@"
	;;
checkout|co)
	shift
	. "$_FLUXO_SCRIPTS_DIR/cmd_checkout.sh"
	_lib_run _parse_help_args "$@"
	_lib_run checkout_fluxo "$@"
	;;
drafts|dt)
	shift
	. "$_FLUXO_SCRIPTS_DIR/cmd_show_fluxo.sh"
	_lib_run _parse_help_args "$@"
	_lib_run show_fluxo --drafts "$@"
	;;
diff|d)
	shift
	. "$_FLUXO_SCRIPTS_DIR/cmd_generate_fluxo_diff_files.sh"

	_lib_run _parse_help_args "$@"
	_lib_run generate_fluxo_diff_files "$@"
	;;
rebase|r)
	shift
	. "$_FLUXO_SCRIPTS_DIR/cmd_rebase_fluxo.sh"
	_lib_run _parse_help_args "$@"
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
