#!/bin/bash

onError() {
  local parent_lineno="$1"
  local message="$2"
  local code="${3:-1}"
  if [[ -n "$message" ]] ; then
    echo "Error on or near line ${parent_lineno}: ${message}; exiting with status ${code}"
  else
    echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
  fi

  git checkout -- app/build.gradle
  exit "${code}"
}
trap 'error ${LINENO}' ERR
trap "exit" INT

cd "$(dirname "$0")"
cd ..

# Check if we're on main
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$BRANCH" != "main" ]]; then
  echo 'Not on main branch! Switch to main and try again.';
  exit 1;
fi

if [ -z "$(git status --porcelain)" ]; then
  # Working directory clean
  echo '';
else
  # Uncommitted changes
  echo 'Working directory not clean! Commit/Revert changes and try again.';
  exit 1;
fi


cd ios

# Credentials
bundle exec fastlane match appstore --readonly --git_url=https://github.com/Colorwaver/certificates

# Increment version
bundle exec fastlane bump
git add ios/Colorwaver/Info.plist

# Increment version
bundle exec fastlane bump
git add app/build.gradle

set -e
bundle exec fastlane release
git commit -m "Bump version for Android Release"
git push
