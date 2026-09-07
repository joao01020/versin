#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${VERSIN_TEST_ROOT:-$HOME/.local/share/versin-test-profiles}"
mkdir -p "$ROOT"
for ID in A B; do
  DIR="$ROOT/$ID"
  mkdir -p "$DIR"
  if test -f "$DIR/app.pid" && kill -0 "$(cat "$DIR/app.pid")" 2>/dev/null; then
    echo "Perfil $ID já está em execução."
    continue
  fi
  nohup "$HERE/run_profile.sh" "$ID" > "$DIR/app.log" 2>&1 < /dev/null &
  echo "$!" > "$DIR/app.pid"
  echo "Perfil $ID iniciado. Log: $DIR/app.log"
done
echo "Use duas contas de teste diferentes. O backend continua sendo o configurado no .env."
