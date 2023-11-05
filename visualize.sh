#!/bin/bash

# This script will attempt to run a docker container using Docker or Podman.
# It will use `docker` with `sudo` if Docker is available, otherwise it will use `podman` if available.
# If neither command is available, it will output an error message.

run_container="run --rm -it -p 9000:9000 -v $(pwd):/src im2nguyen/rover"

# Function to check if a command exists
command_exists() {
    type "$1" &>/dev/null
}

if command_exists docker; then
    echo "Running with Docker..."
    sudo docker $run_container

elif command_exists podman; then
    echo "Running with Podman..."
    podman $run_container

else
    echo "Error: Neither 'docker' nor 'podman' is available on this system."
    exit 1
fi
