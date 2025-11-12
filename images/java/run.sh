#!/bin/bash
set -euo pipefail

# /app = mounted volume (potentially noexec)
# /runner = internal WORKDIR (safe to exec)

# 1. Copy source files from /app (volume) to /runner (internal)
#    We create empty output/error files in /app so they exist
#    for the 'finally' block in the worker, even if we fail early.
touch /app/output.txt
touch /app/error.txt

# Exit gracefully and write to /app/error.txt if files are missing
cp /app/Main.java /runner/Main.java || { echo "Failed to find Main.java" > /app/error.txt; exit 0; }
cp /app/input.txt /runner/input.txt || { echo "Failed to find input.txt" > /app/error.txt; exit 0; }

# 2. Move to internal dir
cd /runner

# 3. Compile
javac Main.java 2> compile.err || true

# 4. Handle Compile Error (copy error back to /app)
if [ -s compile.err ]; then
  echo "Compilation Error:" > /app/error.txt
  cat compile.err >> /app/error.txt
  exit 0 # Exit gracefully so worker can read error.txt
fi

# 5. Run (all files are local in /runner)
timeout 2s java Main < input.txt > output.txt 2> runtime.err || true

# 6. Handle Runtime Error (copy error back to /app)
if [ -s runtime.err ]; then
  echo "Runtime Error:" >> /app/error.txt
  cat runtime.err >> /app/error.txt
fi

# 7. Copy final results back to the mounted /app volume
#    (Only copy if they were created)
if [ -f output.txt ]; then
    cp output.txt /app/output.txt
fi