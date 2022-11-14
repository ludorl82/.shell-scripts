#!/bin/bash

ENV=console CLIENT=terminal ssh -o SendEnv=ENV -o SendEnv=CLIENT -p 2222 localhost
