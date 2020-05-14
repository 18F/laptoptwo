if ! command -v brew > /dev/null; then
    printf "[SYSTEM] You may be prompted for your password."
    printf "[SYSTEM] Install Homebrew and Cask\n"
    ruby -e "$(curl --location --fail --silent --show-error https://raw.githubusercontent.com/Homebrew/install/master/install)"

  case "$SHELL" in
    */fish) :
      # noop, fish ships with /usr/local/bin in a good spot in the path
      ;;
    *) :
      # shellcheck disable=SC2016
      append_to_shell_file 'export PATH="/usr/local/bin:$PATH"'
      ;;
  esac
else
    printf "[SYSTEM] Update Homebrew\n"
    brew update
fi

printf "\n"