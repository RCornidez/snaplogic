#!/bin/bash
set -euo pipefail

# -----------------------
# Purpose:
#   In GitHub Actions, detect changed files between the event's "before" and current commit,
#   classify into pipeline changes (*.slp) vs asset changes (non-.slp),
#   and emit outputs: all_changed, pipeline_changed, asset_changed.
# -----------------------


# fetch last two commits
git fetch --depth=2 || true


# handle initial commit
BEFORE="${GITHUB_EVENT_BEFORE:-}"
if [[ "$BEFORE" == "0000000000000000000000000000000000000000" || -z "$BEFORE" ]]; then
  # Fallback to parent of HEAD; if that fails, use HEAD itself.
  if parent=$(git rev-parse "${GITHUB_SHA}^" 2>/dev/null); then
    BEFORE=$parent
  else
    BEFORE=$GITHUB_SHA
  fi
fi

# List all changed files between BEFORE and HEAD.
CHANGED=$(git diff --name-only "$BEFORE" "${GITHUB_SHA}")

# Detect pipeline changes
slp_changes=$(printf '%s\n' "$CHANGED" | grep -E '\.slp$' || true)

# Detect asset changes (anything not .slp)
asset_changes=$(printf '%s\n' "$CHANGED" | grep -vE '\.slp$' || true)

# Set boolean flags
pipeline_changed=false
asset_changed=false
if [[ -n "$slp_changes" ]]; then
  pipeline_changed=true

  # Pass the list of changed pipeline files to Github Actions
  {
    echo "pipeline_files<<EOF"
    printf '%s\n' "$slp_changes"
    echo "EOF"
  } >> "$GITHUB_OUTPUT"
fi
if [[ -n "$asset_changes" ]]; then
  asset_changed=true
fi

# -----------------------
# pass the flags to to GitHub Actions.
# -----------------------
echo "pipeline_changed=$pipeline_changed" >> "$GITHUB_OUTPUT"
echo "asset_changed=$asset_changed" >> "$GITHUB_OUTPUT"
