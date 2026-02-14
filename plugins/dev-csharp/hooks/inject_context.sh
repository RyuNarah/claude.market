#!/bin/bash

if [ $# -lt 1 ]; then
  echo "Usage: $0 <path>" >&2
  exit 1
fi

search_path="$1"

if [ ! -d "$search_path" ]; then
  echo "Error: '$search_path' is not a valid directory." >&2
  exit 1
fi

context=""
first=true

while IFS= read -r file; do
  if [ "$first" = true ]; then
    first=false
  else
    context="${context}"$'\n\n'
  fi
  content=$(cat "$file")
  context="${context}${content}"
done < <(find "$search_path" -type f -name "*.md" | sort)

# JSON escape without jq: backslash, quotes, tabs, then newlines
escaped="$context"
escaped="${escaped//\\/\\\\}"
escaped="${escaped//\"/\\\"}"
escaped="${escaped//$'\t'/\\t}"
escaped="${escaped//$'\n'/\\n}"

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "${escaped}"
  }
}
EOF
