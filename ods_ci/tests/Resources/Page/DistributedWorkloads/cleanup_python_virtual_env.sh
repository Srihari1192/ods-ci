#!/bin/bash

PYTHON_VERSION="3.9"
VIRTUAL_ENV_NAME="venv$PYTHON_VERSION"

# Function to delete a virtual environment
delete_virtualenv() {
  if [ -d "$VIRTUAL_ENV_NAME" ]; then
    rm -rf "$VIRTUAL_ENV_NAME"
    echo "Virtual environment $VIRTUAL_ENV_NAME deleted successfully."
  else
    echo "Virtual environment $VIRTUAL_ENV_NAME not found."
  fi
}

# Delete Virtual Environment
delete_virtualenv

