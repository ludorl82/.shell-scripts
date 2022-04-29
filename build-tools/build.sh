#!/bin/bash

# Create tmp folder
mkdir -p tmp/

# Populate vars
USER="$(whoami)"

# Build console
read -p "Build console (y|n)? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
  docker build . --iidfile tmp/iid-console --label maintainer=$USER --build-arg USER=$USER -t console -f Dockerfile-console
fi

# Build tools
for tool in $(ls Dockerfile-*); do
  if [ "$tool" != "Dockerfile-console" ]; then
    t=${tool//Dockerfile-/} 
    read -p "Build $t (y|n)? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      docker build . --iidfile tmp/iid-$t --label maintainer=$USER --build-arg USER=$USER -t $t -f $tool
    fi
  fi
done
