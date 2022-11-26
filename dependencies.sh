#!/bin/bash

#Project dependencies file
#Final authority on what's required to fully build the project

# byond version
# Extracted from the Dockerfile. Change by editing Dockerfile's FROM command.
# LIST=($(sed -n 's/.*byond:\([0-9]\+\)\.\([0-9]\+\).*/\1 \2/p' Dockerfile))
# export BYOND_MAJOR=${LIST[0]}
# export BYOND_MINOR=${LIST[1]}
# unset LIST

export BYOND_MAJOR=514
export BYOND_MINOR=1588

# SpacemanDMM git tag
export SPACEMAN_DMM_VERSION=suite-1.7.2

# Python version for mapmerge and other tools
export PYTHON_VERSION=3.7.9
