# Installation

No installation is really necessary. You can run the **bash_scripts/fluxo.sh** shell script from here, or symlink it wherever you want. If you want a global **fluxo** command, you could install this thing with npm or basher. But again, that's not really necessary.

## with [npm](https://www.npmjs.com/)

Yes, you can install this bash program that's not based in Node at all, using npm. Why is a bash program in npm anyway? It's fine. Bits don't judge – as wisely said by [isaacs](https://github.com/isaacs/nave/commit/d2b9b1335ea128420ba367fcea4eae2e51725e36#diff-04c6e90faac2675aa89e2176d2eec7d8R21-R22)

```bash
npm install -g @acaelum/fluxo
```

## with [basher](https://github.com/basherpm/basher)

```bash
basher install artdiniz/fluxo
```

# Install manually

  1. Clone this repository in any folder of your choice, e.g. `~/the/folder`
  ```
  cd ~/the/folder
  git clone https://github.com/artdiniz/fluxo.git
  ```
  2. Enable execution permissions for all cloned files:
    
  ```bash
  chmod -R +x ~/the/folder/fluxo
  ```

  3. Get it to

  ```
  ln -s ~/the/folder/fluxo/bash_scripts/fluxo /usr/local/bin/fluxo
  ```
  
# Usage

You can run `fluxo --help` for usage info:

 ```
  fluxo <show | diff | rebase | doctor>
  fluxo <-h|--help>

  $(tput bold)ACTIONS$(tput sgr0)

    -h | --help      Show detailed instructions

  $(tput bold)FLUXO COMMANDS$(tput sgr0)

    <show | s>           Show branches orderes by fluxo
    <diff | d>           Generate code diff files for each fluxo step
    <rebase | r>         Rebase after changing any fluxo previous steps
    <doctor | dr>        Check fluxo health (Are steps synchronized?)
 ```

Usage info is available in almost all commands.
