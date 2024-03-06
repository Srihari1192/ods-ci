#!/bin/bash

PYTHON_VERSION="3.9"
VIRTUAL_ENV_NAME="venv$PYTHON_VERSION"

# Function to check if a command is available
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to install Python 3.9
install_python() {
  echo "Setting up python$PYTHON_VERSION "
  OS=$(uname -s)

  if [ "$OS" == "Linux" ]; then
    if command_exists dnf; then
      sudo dnf install -y "python$PYTHON_VERSION"
    elif command_exists yum; then
      sudo yum install -y "python$PYTHON_VERSION"
    else
      echo "Unsupported package manager"
      exit 1
    fi
  elif [ "$OS" == "Darwin" ]; then
    brew install "python@$PYTHON_VERSION"
  else
    echo "Unsupported operating system: $OS"
    exit 1
  fi
}

# Function to install virtualenv
install_virtualenv() {
  if ! command_exists virtualenv; then
    pip install virtualenv
  fi
}

# Check and install Python 3.9
if ! command_exists "python$PYTHON_VERSION"; then
  install_python
fi

# Check and install virtualenv
install_virtualenv

# Create a virtual environment
virtualenv -p "python$PYTHON_VERSION" venv3.9

echo "Virtual environment $VIRTUAL_ENV_NAME created successfully."
