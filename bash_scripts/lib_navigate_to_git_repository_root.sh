#!/usr/bin/env bash 
set -e

function navigate_to_git_repository_root {
    . "$(git --exec-path)/git-sh-setup"
    require_work_tree_exists
    cd_to_toplevel
}