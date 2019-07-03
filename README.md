# Install

  1. Clone this repository in any folder of your choice, e.g. `~/the/folder`
  ```
  cd ~/the/folder
  git clone https://github.com/artdiniz/fluxo.git
  ```
  2. Enable execution permissions for all cloned files:
    
  ```bash
  chmod -R +x ~/the/folder
  ```
  3. Create a git alias in `~/.gitconfig` pointing to the fluxo bash script file:
  ```
  [alias]
    fluxo = !bash ~/the/folder/fluxo/bash_scripts/fluxo
  ```
  
# Usage

You can run `git fluxo -- --help` for usage info:

 ```
  git fluxo <show | diff | rebase | doctor>
  git fluxo -- <-h|--help>

  $(tput bold)ACTIONS$(tput sgr0)

    -h | --help      Show detailed instructions

  $(tput bold)FLUXO COMMANDS$(tput sgr0)

    <show | s>           Show branches orderes by fluxo
    <diff | d>           Generate code diff files for each fluxo step
    <rebase | r>         Rebase after changing any fluxo previous steps
    <doctor | dr>        Check fluxo health (Are steps synchronized?)
  ```

Usage info is available in almost all commands.
