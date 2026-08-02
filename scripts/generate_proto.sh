#!/bin/bash
set -e

PATH=$PATH:/home/tharan/Development/flutter/bin:~/.pub-cache/bin

OUTPUT_DIR="./lib/core/generated/proto"
mkdir -p "$OUTPUT_DIR"

echo "Generating Dart Protobuf contracts..."
protoc --proto_path=proto --dart_out="$OUTPUT_DIR" proto/*.proto

echo "Protobuf generation completed successfully."
