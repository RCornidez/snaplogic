# create branch name with timestamp and short commit SHA so it's always new
commit_sha=$(git rev-parse --short origin/dev)
timestamp=$(date -u +"%Y%m%d%H%M%S")
promo_branch="promote-dev-to-test-${timestamp}-${commit_sha}"

git checkout -b "$promo_branch" origin/dev
git push origin HEAD

diff_output=$(git diff --name-status origin/test...HEAD)

added_count=$(printf "%s" "$diff_output" | awk '$1=="A"{c++} END{print c+0}')
modified_count=$(printf "%s" "$diff_output" | awk '$1=="M"{c++} END{print c+0}')
deleted_count=$(printf "%s" "$diff_output" | awk '$1=="D"{c++} END{print c+0}')

pr_title="Promote dev into test (${commit_sha})"
pr_body="Automated promotion from \`dev\` into \`test\`.\n**Source commit:** \`${commit_sha}\`\n**Change summary (vs test):**\n- Files added: ${added_count}\n- Files modified: ${modified_count}\n- Files deleted: ${deleted_count}\n"

if ! gh label list | grep -qx auto-promote; then
    gh label create auto-promote --description "Labels auto-generated promotion PRs"
fi

# create the PR
gh pr create \
--base test \
--head "$promo_branch" \
--title "$pr_title" \
--body "$pr_body" \
--label "auto-promote"
