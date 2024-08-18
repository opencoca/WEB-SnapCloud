#!/bin/bash
# Version 1.1

# Copyright (c) Startr LLC. All rights reserved.
# This script is licensed under the GNU Affero General Public License v3.0.
# For more information, see https://www.gnu.org/licenses/agpl-3.0.en.html

# Startr OpenCo™ Run Script

# This simple script builds and runs this directory 's Dockerfile Image
# Set PROJECTPATH to the path of the current directory
PROJECTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Set PROJECT to the lowercase version of the name of this directory
PROJECT=`echo ${PROJECTPATH##*/}|awk '{print tolower($0)}'`
# Set FULL_BRANCH to the name of the current Git branch
FULL_BRANCH=$(git rev-parse --abbrev-ref HEAD)
# Set BRANCH to the lowercase version of this name, with everything after the last forward slash removed
BRANCH=${FULL_BRANCH##*/}
# Set TAG to the output of the git describe --always --tag command, which returns a "unique identifier" for the current commit
TAG=$(git describe --always --tag)

# Print the values of PROJECTPATH, PROJECT, FULL_BRANCH, and BRANCH to the console
echo PROJECTPATH=$PROJECTPATH
echo     PROJECT=$PROJECT
echo FULL_BRANCH=$FULL_BRANCH
echo      BRANCH=$BRANCH

docker run --rm\
    -p 80:80 \
    -v $PROJECTPATH:/app \
    -it openco/$PROJECT-$BRANCH:latest
