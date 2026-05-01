#!/usr/bin/env bash
# Auto-rebuild Survivors.exe + Survivors.zip when source files change,
# then refresh the "latest" GitHub release so the share URL always
# points at the newest build.
#
# Invoked by a Stop hook in .claude/settings.json. Silent skip when no
# source files changed; prints a single JSON systemMessage on rebuild.

PROJECT_DIR="Z:/Claude/survivors-game"
BUILD_DIR="$PROJECT_DIR/build"
GODOT="Z:/Claude/tools/godot/Godot_v4.6-stable_win64.exe"
EXE="$BUILD_DIR/Survivors.exe"
ZIP="$BUILD_DIR/Survivors.zip"
LOG="$BUILD_DIR/auto_build.log"
GH_REPO="AzuXo/swarm-survivors"
RELEASE_TAG="latest"

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

upload_status="skipped"
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

if [ ! -f "$EXE" ] || [ ! -f "$ZIP" ]; then
    echo '{"systemMessage": "Auto-build FAILED — see build/auto_build.log"}'
    exit 1
fi

# Refresh the GitHub release. --clobber overwrites existing assets so the
# stable URL keeps working. Failures here are non-fatal — the local build
# is still good even if upload fails.
{
    echo "--- Uploading release assets ---"
    if gh release upload "$RELEASE_TAG" "$EXE" "$ZIP" \
            --repo "$GH_REPO" --clobber; then
        echo "Upload OK"
    else
        echo "Upload FAILED (exit $?)"
    fi
} >> "$LOG" 2>&1
upload_exit=$?
if [ $upload_exit -eq 0 ]; then
    upload_status="published"
else
    upload_status="local-only (upload failed, see log)"
fi

exe_mb=$(( $(stat -c%s "$EXE" 2>/dev/null || stat -f%z "$EXE") / 1024 / 1024 ))
zip_mb=$(( $(stat -c%s "$ZIP" 2>/dev/null || stat -f%z "$ZIP") / 1024 / 1024 ))
printf '{"systemMessage": "Auto-build: Survivors.exe (%s MB) and Survivors.zip (%s MB) rebuilt at %s — %s"}\n' \
    "$exe_mb" "$zip_mb" "$(date +%H:%M:%S)" "$upload_status"
