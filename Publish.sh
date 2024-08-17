#!/bin/sh

# We'll check what repo we're in based on the path of the git repo
echo "Checking repo..."
echo "Current directory: $(pwd)"
# slice everything before the last / and then slice everything after the last /
REPO_NAME=$(pwd | sed 's/.*\///' | sed 's/.*\///')
echo "Repo name: $REPO_NAME"
echo "TODO: We will publish $REPO_NAME to docker hub
