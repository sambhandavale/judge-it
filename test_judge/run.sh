#!/bin/bash
# Expect code.py, input.txt
set -e
# run with timeout
timeout 2s python code.py < input.txt > output.txt 2> error.txt || true
