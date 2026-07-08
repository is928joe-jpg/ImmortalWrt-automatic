#!/bin/bash
WORKFLOW_FILE="$1"
INPUT_NAME="$2"
shift 2

OPTIONS=""
for val in "$@"; do
    OPTIONS+="          - $val"$'\n'
done

python3 << EOF
import re

with open('.github/workflows/${WORKFLOW_FILE}', 'r') as f:
    content = f.read()

# 匹配 options: [] 或 options: 后面的内容直到下一个非空字段
new_content = re.sub(
    r'(${INPUT_NAME}:.*?options:\s*)\[.*?\]',
    '\\1\n${OPTIONS}        ',
    content,
    flags=re.DOTALL
)

with open('.github/workflows/${WORKFLOW_FILE}', 'w') as f:
    f.write(new_content)

print("Updated ${INPUT_NAME}")
EOF