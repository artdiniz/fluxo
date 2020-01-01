#!/usr/bin/env bash 
set -e

function style_setup {
    local bold_0=$(   tput bold   )
    local under_0=$(  tput smul   )
    local red_0=$(    tput setaf 1)
    local green_0=$(  tput setaf 2)
    local yellow_0=$( tput setaf 3)
    local blue_0=$(   tput setaf 4)
    local purple_0=$( tput setaf 5)
    local cyan_0=$(   tput setaf 6)
    local grey_0="\033[38;5;242m"
    local reset_0=$(  tput sgr0   )
    

    RED="$red_0"
    GREEN="$green_0"
    YELLOW="$yellow_0"
    BLUE="$blue_0"
    PURPLE="$purple_0"
    CYAN="$cyan_0"
    GREY="$grey_0"
    BOLD="$bold_0"
    UNDERLINE="$under_0"
    RESET="$reset_0"
}
style_setup

function style {

    local styles=$1
    local text=$2

    echo "$styles$text$RESET"
}