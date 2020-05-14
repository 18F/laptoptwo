if ! command -v python > /dev/null; then
    brew install python
else
    export PYTHON_VERSION=`python -c "print(__import__('sys').version_info[:1])"`
    # This will yield a tuple like (3,) which can be checked for a major version number.
    if [[ $PYTHON_VERSION =~ "2." ]]; then
        printf "[PYTHON] Installing python3 via Homebrew.\n"
        brew install python
    fi
    if [[ $PYTHON_VERSION =~ "3." ]]; then
        printf "[PYTHON] Version 3 already installed.\n"
    fi
fi
