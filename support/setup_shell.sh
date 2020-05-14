
append_to_file() {
  # shellcheck disable=SC2039
  local file="$1"
  # shellcheck disable=SC2039
  local text="$2"

  if [ "$file" = "$HOME/.zshrc" ]; then
    if [ -w "$HOME/.zshrc.local" ]; then
      file="$HOME/.zshrc.local"
    else
      file="$HOME/.zshrc"
    fi
  fi

  if ! grep -qs "^$text$" "$file"; then
    printf "\n%s\n" "$text" >> "$file"
  fi
}

append_to_shell_file() {
  append_to_file "$shell_file" "$1"
}

create_and_set_shell_file() {
  shell_file="$1"
  if [ ! -f "$shell_file" ]; then
    touch "$shell_file"
  fi
}

create_zshrc_and_set_it_as_shell_file() {
  create_and_set_shell_file "$HOME/.zshrc"
}

create_fishconfig_and_set_it_as_shell_file() {
  create_and_set_shell_file "$HOME/.config/fish/config.fish"
}

create_bash_profile_and_set_it_as_shell_file() {
  create_and_set_shell_file "$HOME/.bash_profile"
}

# shellcheck disable=SC2154
trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT

set -e

if [ ! -d "$HOME/.bin/" ]; then
  mkdir "$HOME/.bin"
fi

case "$SHELL" in
  */fish) :
    create_fishconfig_and_set_it_as_shell_file
    ;;
  */zsh) :
    create_zshrc_and_set_it_as_shell_file
    ;;
  *)
    create_bash_profile_and_set_it_as_shell_file
    if [ -z "$CI" ]; then
      bold=$(tput bold)
      normal=$(tput sgr0)
      echo "Want to switch your shell from the default ${bold}bash${normal} to ${bold}zsh${normal}?"
      echo "Both work fine for development, and ${bold}zsh${normal} has some extra "
      echo "features for customization and tab completion."
      echo "If you aren't sure or don't care, we recommend ${bold}zsh${normal}."
      echo "Note that you can always switch back to ${bold}bash${normal} if you change your mind."
      echo "Please see the README for instructions."
      echo -n "Press ${bold}y${normal} to switch to zsh, ${bold}n${normal} to keep bash: "
      read -r -n 1 response
      if [ "$response" = "y" ]; then
        create_zshrc_and_set_it_as_shell_file
        if grep "$(command -v zsh)" > /dev/null 2>&1 < /etc/shells; then
          fancy_echo "=== Getting ready to change your shell to zsh. Please enter your password to continue. ==="
          echo "=== Note that there won't be visual feedback when you type your password. Type it slowly and press return. ==="
          echo "=== Press control-c to cancel ==="
          chsh -s "$(command -v zsh)"
        else
          printf "\n\n"
          echo "Can't switch shells automatically in this case.  The path to zsh isn't in"
          echo "the list of allowed shells.  To manually switch to zsh, enter the following"
          echo "two lines into your terminal (in another tab, or when this script is done):"
          echo ""
          echo "sudo echo \"\$(command -v zh)\" >> /etc/shells"
          echo "chsh -s \"\$(command -v zs)\""
          sleep 3
        fi
      else
        fancy_echo "Shell will not be changed."
      fi
    else
      fancy_echo "CI System detected, will not change shells"
    fi
    ;;
esac
