#!/usr/bin/env bash
set -euo pipefail
ID="${1:-}"
case "$ID" in A|B) ;; *) echo "Uso: $0 A|B"; exit 2;; esac
ROOT="${VERSIN_TEST_ROOT:-$HOME/.local/share/versin-test-profiles}"
DIR="$ROOT/$ID"
APP="$DIR/bundle/versin"
test -x "$APP" || { echo "Compile primeiro: ./tool/versin_test_profiles/build_profiles.sh"; exit 1; }
test "$(cat "$DIR/profile.txt" 2>/dev/null)" = "$ID" || { echo "Perfil do bundle não confere."; exit 1; }
mkdir -p "$DIR/config" "$DIR/data" "$DIR/cache"
export XDG_CONFIG_HOME="$DIR/config"
export XDG_DATA_HOME="$DIR/data"
export XDG_CACHE_HOME="$DIR/cache"
# Keep HOME, XDG_RUNTIME_DIR, DBus, Wayland and audio sockets unchanged.
# The native secure store is shared by the OS, but the Dart keys are namespaced.
cd "$DIR/bundle"
echo "Versin $ID — dados locais: $DIR"
exec "$APP"
