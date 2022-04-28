#!/bin/bash

# Build console
USER="$(whoami)"
docker build . --label maintainer=$USER --build-arg USER=$USER
