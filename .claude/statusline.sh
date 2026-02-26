#!/bin/bash
command -v jq >/dev/null || { echo "jq required"; exit 1; }
input=$(cat)

IFS=$'\t' read -r MODEL CONTEXT_PCT < <(echo "$input" | jq -r '[.model.display_name // "Unknown", (.context_window.used_percentage // 0 | floor | tostring)] | join("\t")')

BRANCH=$(git branch --show-current 2>/dev/null)
: "${BRANCH:=$(git rev-parse --short HEAD 2>/dev/null || echo 'no git')}"

echo "$MODEL | Context ${CONTEXT_PCT}% | $BRANCH"
