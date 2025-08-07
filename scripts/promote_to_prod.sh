#!/usr/bin/env bash
# Fail hard on any error or unset var
set -euo pipefail

# Derive the tag name
TAG=${GITHUB_REF:-}
TAG=${TAG#refs/tags/}

# Determine the commit & branch names
SHA=$(git rev-parse "$TAG")
BRANCH="promote-${TAG}"
BASE_BRANCH="prod"

# Bail out early if there’s nothing new to promote
if git merge-base --is-ancestor "$SHA" "origin/$BASE_BRANCH"; then
  echo "::notice:: $TAG is already in $BASE_BRANCH — nothing to promote."
  exit 0
fi

# Create a promo branch at the tagged commit
git checkout -b "$BRANCH" "$SHA"
git push -u origin "$BRANCH"

# Open a promotion PR
gh pr create \
  --base "$BASE_BRANCH" \
  --head "$BRANCH" \
  --title "Promote $TAG to $BASE_BRANCH" \
  --body "Automated PR to promote tag \`$TAG\` (\`$SHA\`) into **$BASE_BRANCH**." \
  --label release
