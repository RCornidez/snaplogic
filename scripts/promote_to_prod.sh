TAG=${GITHUB_REF#refs/tags/}
SHA=$(git rev-parse "$TAG")

BRANCH="promote-${TAG}"
git checkout -b "$BRANCH" "$SHA"
git push -u origin "$BRANCH"

if ! gh label list | grep -qx release; then
gh label create release --description "Labels auto-generated release PRs"
fi

gh pr create \
--base production \
--head "$BRANCH" \
--title "Promote $TAG to production" \
--body "Automated PR to promote tag \`$TAG\` (`$SHA`) into **production**." \
--label release