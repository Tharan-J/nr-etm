#!/bin/bash
set -e

PATH=$PATH:/home/tharan/Development/flutter/bin:~/.pub-cache/bin

echo "Running code generation..."
./scripts/generate_proto.sh
/home/tharan/Development/flutter/bin/dart run build_runner build

echo "Code generation pipeline complete."
