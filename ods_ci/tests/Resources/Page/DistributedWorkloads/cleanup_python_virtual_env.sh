#!/bin/bash

PYTHON_VERSION="3.9"
VIRTUAL_ENV_NAME="venv$PYTHON_VERSION"

# Function to check if a command is available
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to uninstall Python 3.9
uninstall_python() {
  OS=$(uname -s)

  if [ "$OS" == "Linux" ]; then
    if command_exists apt-get; then
      sudo apt-get remove -y "python$PYTHON_VERSION"
      echo "Python $PYTHON_VERSION uninstalled"
    elif command_exists dnf; then
      sudo dnf remove -y "python$PYTHON_VERSION"
      echo "Python $PYTHON_VERSION uninstalled"
    else
      echo "Unsupported package manager for Linux"
      exit 1
    fi
  elif [ "$OS" == "Darwin" ]; then
    brew uninstall "python@$PYTHON_VERSION"
    echo "Python $PYTHON_VERSION uninstalled"
  else
    echo "Unsupported operating system: $OS"
    exit 1
  fi
}

# Function to delete a virtual environment
delete_virtualenv() {
  if [ -d "$VIRTUAL_ENV_NAME" ]; then
    rm -rf "$VIRTUAL_ENV_NAME"
    echo "Virtual environment $VIRTUAL_ENV_NAME deleted successfully."
  else
    echo "Virtual environment $VIRTUAL_ENV_NAME not found."
  fi
}

# Uninstall Python 3.9
uninstall_python

# Delete Virtual Environment
delete_virtualenv

