#!/bin/bash

# Build console
USER="$(whoami)"
docker build . --iidfile iid --label maintainer=$USER --build-arg USER=$USER
