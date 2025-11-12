#!/bin/bash
set -euo pipefail

# /app = mounted volume (potentially noexec)
# /runner = internal WORKDIR (safe to exec)

# 1. Create empty output files in /app so they always exist
touch /app/output.txt
touch /app/error.txt

# 2. Copy source files from /app (volume) to /runner (internal)
cp /app/code.c /runner/code.c || { echo "Failed to find code.c" > /app/error.txt; exit 0; }
cp /app/input.txt /runner/input.txt || { echo "Failed to find input.txt" > /app/error.txt; exit 0; }

# 3. Move to internal dir
cd /runner

# 4. Compile (Using gcc for .c files, and std=c17)
gcc code.c -O2 -std=c17 -lm -o code.out 2> compile.err || true

# 5. Handle Compile Error (copy error back to /app)
if [ -s compile.err ]; then
  echo "Compilation Error:" > /app/error.txt
  cat compile.err >> /app/error.txt
  exit 0 # Exit gracefully so worker can read error.txt
fi

# 6. Run (all files are local in /runner)
timeout --preserve-status 2s ./code.out < input.txt > output.txt 2> runtime.err || true

# 7. Handle Runtime Error (copy error back to /app)
if [ -s runtime.err ]; then
  echo "Runtime Error:" >> /app/error.txt
  cat runtime.err >> /app/error.txt
fi

# 8. Copy final results back to the mounted /app volume
if [ -f output.txt ]; then
    cp output.txt /app/output.txt
fi