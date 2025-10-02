#!/bin/bash

PACKAGE="sddm"

# Parse options
while getopts "f:h" opt; do
  case $opt in
    f) FEDORA_VERSION="$OPTARG" ;;
    h)
      cat <<EOF
Branch off from an upstream Fedora branch of $PACKAGE and mark it as the build source.

Usage: $0 [-f fedora_version]
  -f  Specify the Fedora release version
  -h  Show this help message

Example:
  $0
  $0 -f 43
EOF
      exit 0
      ;;
    *)
      echo "Usage: $0 [-f fedora_version]" >&2
      exit 1
      ;;
  esac
done

# Set Fedora release version
if [ -z "$FEDORA_VERSION" ]; then
  # Find the host's Fedora version
  HOST_FEDORA_VERSION=$(rpm -E %fedora)

  read -rp "Fedora release version (default: $HOST_FEDORA_VERSION): " FEDORA_VERSION
  FEDORA_VERSION="${FEDORA_VERSION:-$HOST_FEDORA_VERSION}"
fi

if [ -z "$FEDORA_VERSION" ]; then
  echo "❌ No Fedora version specified"
  exit 1
fi

# Fetch the corresponding branch from upstream
UPSTREAM_BRANCH="f$FEDORA_VERSION"
printf "\r\e[K📥 Fetching branch %s from upstream" "$UPSTREAM_BRANCH"
git fetch upstream "$UPSTREAM_BRANCH" 2>&1 | while read -r line; do
  printf "\r\e[K📥 %s" "${line:0:(($COLUMNS - 3))}"
done

if [ "${PIPESTATUS[0]}" -ne 0 ]; then
  printf "\r\e[K❌ Failed to fetch branch %s\n" "$UPSTREAM_BRANCH"
  exit 1
fi

printf "\r\e[K🏷 Upstream branch: %s\n" "$UPSTREAM_BRANCH"

# Clear git note on the root commit
ROOT_COMMIT=$(git rev-list --max-parents=0 HEAD)

if git notes --ref "f$FEDORA_VERSION" show "$ROOT_COMMIT" &>/dev/null; then
  git notes --ref "f$FEDORA_VERSION" remove "$ROOT_COMMIT" &>/dev/null
fi

# Mark branch as the build source in the git note
BRANCH="customize/$UPSTREAM_BRANCH"
git notes --ref "f$FEDORA_VERSION" add -m "$BRANCH" "$ROOT_COMMIT"
printf "\r\e[K📤 Marking %s as the build branch" "$BRANCH"
git push origin "refs/notes/f$FEDORA_VERSION" --force 2>&1 | while read -r line; do
  printf "\r\e[K📤 %s" "${line:0:(($COLUMNS - 3))}"
done

if [ "${PIPESTATUS[0]}" -ne 0 ]; then
  printf "\r\e[K❌ Failed to mark %s as the build branch\n" "$BRANCH"
  exit 1
fi

printf "\r\e[K📝 Root commit note: %s\n" "$BRANCH"

# Branch off upstream branch
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  printf "\r\e[K🟢 Branch %s already exists\n" "$BRANCH"
  git checkout "$BRANCH" &>/dev/null
  exit 0
fi

git checkout -b "$BRANCH" "upstream/$UPSTREAM_BRANCH" &>/dev/null
printf "\r\e[K✨ New branch %s created\n" "$BRANCH"
