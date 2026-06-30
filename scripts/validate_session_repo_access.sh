#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <repo_url>"
  exit 1
fi

REPO_URL="$1"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if git ls-remote "$REPO_URL" >/dev/null 2>&1; then
  echo "ACCESS_OK: session can access $REPO_URL"
  exit 0
fi

echo "ACCESS_DENIED: session cannot access $REPO_URL"
exit 2
