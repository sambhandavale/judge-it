#!/bin/bash
set -euo pipefail

# /app = mounted volume (potentially noexec)
# /runner = internal WORKDIR (safe to exec)

# 1. Copy source files from /app (volume) to /runner (internal)
#    We create empty output/error files in /app so they exist
#    for the 'finally' block in the worker, even if we fail early.
touch /app/output.txt
touch /app/error.txt

cp /app/code.cpp /runner/code.cpp || { echo "Failed to find code.cpp" > /app/error.txt; exit 0; }
cp /app/input.txt /runner/input.txt || { echo "Failed to find input.txt" > /app/error.txt; exit 0; }

# 2. Move to internal dir
cd /runner

# 3. Compile
g++ code.cpp -O2 -std=c++17 -o code.out 2> compile.err || true

# 4. Handle Compile Error (copy error back to /app)
if [ -s compile.err ]; then
  echo "Compilation Error:" > /app/error.txt
  cat compile.err >> /app/error.txt
  exit 0 # Exit gracefully so worker can read error.txt
fi

# 5. Run (all files are local in /runner)
timeout --preserve-status 2s ./code.out < input.txt > output.txt 2> runtime.err || true

# 6. Handle Runtime Error (copy error back to /app)
if [ -s runtime.err ]; then
  echo "Runtime Error:" >> /app/error.txt
  cat runtime.err >> /app/error.txt
fi

# 7. Truncate output if needed (do this on the local file)
MAX_BYTES=1000000 # 1MB
if [ -f output.txt ] && [ $(stat -c%s "output.txt") -gt $MAX_BYTES ]; then
  echo "Output truncated (too large)." >> /app/error.txt
  head -c $MAX_BYTES output.txt > tmp.txt && mv tmp.txt output.txt
fi

# 8. Copy final results back to the mounted /app volume
if [ -f output.txt ]; then
    cp output.txt /app/output.txt
fi