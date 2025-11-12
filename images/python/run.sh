#!/bin/bash
set -e
cd /app || exit 1
ls -l    # <-- see if input.txt exists

timeout 2s python3 code.py < input.txt > output.txt 2> error.txt || true
