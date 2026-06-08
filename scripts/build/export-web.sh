#!/usr/bin/env bash
# Export Remi's World for the browser and copy into the Vite public folder.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
EXPORT_DIR="$ROOT/exports/remiworld-web"
WEB_GAME_DIR="$ROOT/web/public/game"
PRESET_NAME="Web"

find_godot() {
  if [[ -n "${GODOT:-}" && -x "$GODOT" ]]; then
    echo "$GODOT"
    return
  fi
  if command -v godot >/dev/null 2>&1; then
    command -v godot
    return
  fi
  if [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
    echo "/Applications/Godot.app/Contents/MacOS/Godot"
    return
  fi
  return 1
}

GODOT_BIN="$(find_godot || true)"
if [[ -z "$GODOT_BIN" ]]; then
  if [[ -f "$WEB_GAME_DIR/index.html" ]]; then
    echo "[export-web] Godot not found — using existing web/public/game build."
    exit 0
  fi
  echo "[export-web] ERROR: Godot not found and no existing build in web/public/game." >&2
  echo "Install Godot 4.6+ or set GODOT=/path/to/Godot" >&2
  exit 1
fi

echo "[export-web] Using Godot: $GODOT_BIN"
mkdir -p "$EXPORT_DIR" "$WEB_GAME_DIR" "$ROOT/.godot/editor" "$ROOT/.godot/imported"

# Import assets first (needed for reliable headless export)
"$GODOT_BIN" --headless --path "$ROOT" --import >/dev/null 2>&1 || true

if ! "$GODOT_BIN" --headless --path "$ROOT" --export-release "$PRESET_NAME" "$EXPORT_DIR/index.html"; then
  echo "" >&2
  echo "[export-web] Export failed. Common fix: install Web export templates in Godot:" >&2
  echo "  Editor → Manage Export Templates → Download and Install (4.6.3)" >&2
  echo "  Or: Editor → Export → Web → Export Project (creates the same files)" >&2
  exit 1
fi

echo "[export-web] Copying export to web/public/game ..."
rm -rf "$WEB_GAME_DIR"/*
cp -R "$EXPORT_DIR/"* "$WEB_GAME_DIR/"

echo "[export-web] Done. Game files ready at web/public/game/"
