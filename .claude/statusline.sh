#!/bin/bash
input=$(cat)

eval "$(echo "$input" | jq -r '
  "MODEL=\"\(.model.display_name // "Unknown")\"",
  "INPUT_TOKENS=\(.context_window.total_input_tokens // 0)",
  "OUTPUT_TOKENS=\(.context_window.total_output_tokens // 0)",
  "CONTEXT_SIZE=\(.context_window.context_window_size // 0)"
')"

TOTAL_TOKENS=$((INPUT_TOKENS + OUTPUT_TOKENS))
CONTEXT_PCT=$((CONTEXT_SIZE > 0 ? TOTAL_TOKENS * 100 / CONTEXT_SIZE : 0))

echo "$MODEL | Context ${CONTEXT_PCT}%"
