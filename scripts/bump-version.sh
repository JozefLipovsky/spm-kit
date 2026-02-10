#!/bin/bash

# scripts/bump-version.sh
# Usage: ./scripts/bump-version.sh [patch|minor|major]

set -e

BUMP_LEVEL=$1
VERSION_FILE="Sources/SPMKit/SPMKit.swift"

if [[ -z "$BUMP_LEVEL" ]]; then
  echo "Usage: $0 [patch|minor|major]"
  exit 1
fi

# Extract current version
CURRENT_VERSION=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$VERSION_FILE" | head -n 1)
if [[ -z "$CURRENT_VERSION" ]]; then
  echo "Error: Could not find version string in $VERSION_FILE"
  exit 1
fi

echo "Current version: $CURRENT_VERSION"

# Split version into parts
IFS='.' read -ra ADDR <<< "$CURRENT_VERSION"
MAJOR=${ADDR[0]}
MINOR=${ADDR[1]}
PATCH=${ADDR[2]}

# Bump based on level
case "$BUMP_LEVEL" in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
  *)
    echo "Error: Invalid bump level '$BUMP_LEVEL'. Use patch, minor, or major."
    exit 1
    ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
echo "New version: $NEW_VERSION"

# Update the file in place, handle both GNU and BSD sed differences for local and CI compatibility
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i "" "s/version: \"$CURRENT_VERSION\"/version: \"$NEW_VERSION\"/g" "$VERSION_FILE"
else
  sed -i "s/version: \"$CURRENT_VERSION\"/version: \"$NEW_VERSION\"/g" "$VERSION_FILE"
fi

# Verification
UPDATED_VERSION=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$VERSION_FILE" | head -n 1)
if [[ "$UPDATED_VERSION" != "$NEW_VERSION" ]]; then
  echo "Error: Failed to update version in $VERSION_FILE"
  exit 1
fi

# Output for GitHub Actions
if [[ -n "$GITHUB_OUTPUT" ]]; then
  echo "new_version=$NEW_VERSION" >> "$GITHUB_OUTPUT"
fi
