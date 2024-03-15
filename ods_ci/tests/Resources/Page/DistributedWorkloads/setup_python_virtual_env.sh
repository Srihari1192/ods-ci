#!/bin/bash

PYTHON_VERSION="3.9"
VIRTUAL_ENV_NAME="venv$PYTHON_VERSION"

# Function to install virtualenv
install_virtualenv() {
  if ! command_exists virtualenv; then
      echo "installing virtual environment"
    pip install virtualenv
  fi
}

# Check and install virtualenv
install_virtualenv

# Create a virtual environment
virtualenv -p "python$PYTHON_VERSION" venv3.9

echo "Virtual environment $VIRTUAL_ENV_NAME created successfully."
