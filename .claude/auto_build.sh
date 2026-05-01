#!/usr/bin/env bash
# Auto-rebuild Survivors.exe + Survivors.zip when source files change.
# Invoked by a Stop hook in .claude/settings.json. Stays silent unless a
# rebuild actually happened, in which case it prints a JSON systemMessage
# so the user gets a single confirmation line in the chat.

PROJECT_DIR="Z:/Claude/survivors-game"
BUILD_DIR="$PROJECT_DIR/build"
GODOT="Z:/Claude/tools/godot/Godot_v4.6-stable_win64.exe"
EXE="$BUILD_DIR/Survivors.exe"
ZIP="$BUILD_DIR/Survivors.zip"
LOG="$BUILD_DIR/auto_build.log"

mkdir -p "$BUILD_DIR"

needs_rebuild() {
    [ ! -f "$EXE" ] && return 0
    [ "$PROJECT_DIR/project.godot" -nt "$EXE" ] && return 0
    [ "$PROJECT_DIR/export_presets.cfg" -nt "$EXE" ] && return 0
    if find "$PROJECT_DIR/scenes" "$PROJECT_DIR/scripts" "$PROJECT_DIR/assets" \
            -type f -newer "$EXE" 2>/dev/null | grep -q .; then
        return 0
    fi
    return 1
}

if ! needs_rebuild; then
    exit 0
fi

{
    echo
    echo "=== $(date) ==="
    "$GODOT" --headless --path "$PROJECT_DIR" \
        --export-release "Windows Desktop" "build/Survivors.exe"
    echo "Export exit: $?"
    rm -f "$ZIP"
    powershell -NoProfile -Command \
        "Compress-Archive -Path '$EXE' -DestinationPath '$ZIP' -CompressionLevel Optimal -Force"
    echo "Zip exit: $?"
} >> "$LOG" 2>&1

if [ -f "$EXE" ] && [ -f "$ZIP" ]; then
    exe_mb=$(( $(stat -c%s "$EXE" 2>/dev/null || stat -f%z "$EXE") / 1024 / 1024 ))
    zip_mb=$(( $(stat -c%s "$ZIP" 2>/dev/null || stat -f%z "$ZIP") / 1024 / 1024 ))
    printf '{"systemMessage": "Auto-build: Survivors.exe (%s MB) and Survivors.zip (%s MB) rebuilt at %s"}\n' \
        "$exe_mb" "$zip_mb" "$(date +%H:%M:%S)"
else
    echo '{"systemMessage": "Auto-build FAILED — see build/auto_build.log"}'
fi
