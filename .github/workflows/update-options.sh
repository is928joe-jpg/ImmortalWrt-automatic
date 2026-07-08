#!/bin/bash
WORKFLOW_FILE="$1"
INPUT_NAME="$2"
shift 2

OPTIONS=""
for val in "$@"; do
    OPTIONS+="          - ${val}\n"
done

python3 << EOF
import re

with open('.github/workflows/${WORKFLOW_FILE}', 'r') as f:
    content = f.read()

new_options = """${OPTIONS}"""

content = re.sub(
    r'(${INPUT_NAME}:.*?options:\s*)\[.*?\]',
    '\\1\\n' + new_options,
    content,
    flags=re.DOTALL
)

with open('.github/workflows/${WORKFLOW_FILE}', 'w') as f:
    f.write(content)

print("Updated ${INPUT_NAME}")
EOF