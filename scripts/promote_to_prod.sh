#!/usr/bin/env bash
# Fail hard on any error or unset var
set -euo pipefail

# 1. Derive the tag name
TAG=${GITHUB_REF:-}          # e.g. refs/tags/v0.1.0 when run from Actions
TAG=${TAG#refs/tags/}        # strip prefix

# 2. Calculate commit & branch names
SHA=$(git rev-parse "$TAG")
BRANCH="promote-${TAG}"
BASE_BRANCH="prod"

# 3. Bail out early if there’s nothing new to promote
if git merge-base --is-ancestor "$SHA" "origin/$BASE_BRANCH"; then
  echo "::notice:: $TAG is already in $BASE_BRANCH — nothing to promote."
  exit 0
fi

# 4. Create a promo branch at the tagged commit
git checkout -b "$BRANCH" "$SHA"
git push -u origin "$BRANCH"

# 5. Open a promotion PR
gh pr create \
  --base "$BASE_BRANCH" \
  --head "$BRANCH" \
  --title "Promote $TAG to $BASE_BRANCH" \
  --body "Automated PR to promote tag \`$TAG\` (\`$SHA\`) into **$BASE_BRANCH**." \
  --label release
