#!/bin/sh
set -eu
PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
GODOT_BIN=${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}
mkdir -p "$PROJECT_ROOT/builds/android" "$PROJECT_ROOT/work"
"$GODOT_BIN" --headless --path "$PROJECT_ROOT" --export-debug Android \
  "$PROJECT_ROOT/builds/android/solar-system-explorer-v0.21.0-debug.apk" \
  --log-file "$PROJECT_ROOT/work/android-export.log"
