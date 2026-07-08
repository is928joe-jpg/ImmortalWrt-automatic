#!/bin/bash
# 用法: ./update-options.sh <workflow-file> <input-name> <value1> <value2> ...
# 示例: ./update-options.sh step2-arch.yml target_arch x86-64 rockchip-armv8

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

new_options = """${OPTIONS}"""

content = re.sub(
    r'(${INPUT_NAME}:.*?options:)\n(.*?)(\n      [a-z])',
    '\\1\n' + new_options + '\\3',
    content,
    flags=re.DOTALL
)

with open('.github/workflows/${WORKFLOW_FILE}', 'w') as f:
    f.write(content)

print("Updated ${INPUT_NAME} in ${WORKFLOW_FILE}")
EOF