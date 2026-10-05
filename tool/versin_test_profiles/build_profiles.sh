#!/usr/bin/env bash
set -euo pipefail
PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ROOT="${VERSIN_TEST_ROOT:-$HOME/.local/share/versin-test-profiles}"
cd "$PROJECT"
test -f pubspec.yaml || { echo "pubspec.yaml não encontrado."; exit 1; }
mkdir -p "$ROOT"
for ID in A B; do
  DIR="$ROOT/$ID"
  if test -f "$DIR/app.pid" && kill -0 "$(cat "$DIR/app.pid")" 2>/dev/null; then
    echo "Feche os dois perfis antes de reconstruir."
    exit 1
  fi
done
flutter pub get
for ID in A B; do
  echo "=== Compilando perfil $ID ==="
  flutter build linux --debug --dart-define="VERSIN_INSTANCE=$ID"
  SRC="$PROJECT/build/linux/x64/debug/bundle"
  test -x "$SRC/versin" || { echo "Executável versin não encontrado: $SRC"; exit 1; }
  DEST="$ROOT/$ID"
  mkdir -p "$DEST"
  # Never overwrite the binary of a running profile.
  if test -f "$DEST/app.pid" && kill -0 "$(cat "$DEST/app.pid")" 2>/dev/null; then
    echo "Feche o perfil $ID antes de reconstruí-lo."
    exit 1
  fi
  rm -rf "$DEST/bundle"
  cp -a "$SRC" "$DEST/bundle"
  printf '%s\n' "$ID" > "$DEST/profile.txt"
done
echo "Perfis compilados em $ROOT/{A,B}/bundle."
echo "Abra com: ./tool/versin_test_profiles/open_two.sh"
