#!/bin/bash
input=$(cat)

eval "$(echo "$input" | jq -r '
  "MODEL=\"\(.model.display_name // \"Unknown\")\"",
  "CONTEXT_PCT=\(.context_window.used_percentage // 0 | floor)"
')"

echo "$MODEL | Context ${CONTEXT_PCT}%"
