#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
BUILD_DIR="$ROOT_DIR/build/windows"
EXPORT_PRESET="Windows Desktop"

if ! command -v godot &>/dev/null; then
  echo "Error: godot executable not found in PATH." >&2
  echo "Install Godot 4.x and ensure 'godot' is available." >&2
  exit 1
fi

mkdir -p "$BUILD_DIR"

echo "Exporting Windows build via Godot..."
godot --headless --path "$ROOT_DIR" --export-release "$EXPORT_PRESET" "$BUILD_DIR/PostManagementGame.exe"

if [[ ! -f "$BUILD_DIR/PostManagementGame.exe" ]]; then
  echo "Error: Windows export failed (missing executable)." >&2
  exit 1
fi

if [[ ! -f "$BUILD_DIR/PostManagementGame.pck" ]]; then
  echo "Error: Windows export failed (missing PCK)." >&2
  exit 1
fi

if ! command -v iscc &>/dev/null; then
  cat <<MSG >&2
Error: Inno Setup Compiler (iscc) not found.
Install Inno Setup 6 or newer and ensure 'iscc' is accessible.
MSG
  exit 1
fi

echo "Building installer with Inno Setup..."
ISCC_SCRIPT="$ROOT_DIR/installer/postmanagement_game.iss"
"$(command -v iscc)" "$ISCC_SCRIPT"

echo "Installer generated at $ROOT_DIR/PostManagementGameSetup.exe"
