#!/usr/bin/env bash
# Run pytest coverage scoped to files changed since main branch.
# Usage: bash .claude/skills/code-review/scripts/check-coverage.sh

set -euo pipefail

CHANGED_FILES=$(git diff --name-only main...HEAD -- '*.py' 2>/dev/null || git diff --name-only HEAD~1 -- '*.py')

if [ -z "$CHANGED_FILES" ]; then
    echo "No Python files changed."
    exit 0
fi

# Build --cov args for each changed source file
COV_ARGS=""
for f in $CHANGED_FILES; do
    if [[ "$f" == src/* ]]; then
        # Convert path to module for coverage
        COV_ARGS="$COV_ARGS --cov=${f%%.py}"
    fi
done

if [ -z "$COV_ARGS" ]; then
    echo "No source files changed (only test files). Running tests..."
    pytest $CHANGED_FILES -v
else
    echo "Running coverage for changed files..."
    echo "Files: $CHANGED_FILES"
    pytest tests/ $COV_ARGS --cov-report=term-missing -v
fi
