#!/bin/bash

PACKAGE="sddm"

# Get the installed version
VERSION=$(rpm -E %fedora)

if [ -z "$VERSION" ]; then
  echo "Unable to retrieve version"
  exit 0
fi

# Fetch upstream branch
UPSTREAM_BRANCH="f$VERSION"
echo "Fetching branch $UPSTREAM_BRANCH from upstream..."
git fetch upstream "$UPSTREAM_BRANCH"

# Clear git note on the root commit
ROOT_COMMIT=$(git rev-list --max-parents=0 HEAD)

if git notes show "$ROOT_COMMIT" &>/dev/null; then
  git notes remove "$ROOT_COMMIT"
fi

# Mark branch as the build source in the git note
BRANCH="customize/$UPSTREAM_BRANCH"
echo "Marking $BRANCH as the build branch..."
git notes add -m "$BRANCH" "$ROOT_COMMIT"
git push origin refs/notes/commits --force

# Branch off upstream branch
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  echo "Branch $BRANCH already exists."
  git checkout "$BRANCH"
  exit 0
fi

echo "Creating branch $BRANCH from upstream branch $UPSTREAM_BRANCH..."
git checkout -b "$BRANCH" "upstream/$UPSTREAM_BRANCH"
