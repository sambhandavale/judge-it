#!/bin/bash
set -euo pipefail

# /app = mounted volume with user code

# 1. Move to the /app directory
cd /app || { echo "Failed to cd into /app"; exit 1; }

# 2. Create empty output files so they always exist for the worker
touch output.txt
touch error.txt

# 3. Run the node interpreter against the code.js file
#    All files (code.js, input.txt, output.txt, error.txt)
#    are read from/written to the /app directory.
timeout 2s node code.js < input.txt > output.txt 2> error.txt || true