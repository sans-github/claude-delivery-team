#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/sans-github/claude-delivery-team"
REF="${1:-main}"
# bash <(curl ...) sets BASH_SOURCE[0] to /dev/fd/N — not a real path.
# curl | bash leaves it empty. Both cases fall back to pwd (consumer's project root).
_src="${BASH_SOURCE[0]:-}"
if [[ -f "$_src" && "$_src" != /dev/* && "$_src" != /proc/* ]]; then
  ROOT="$(cd "$(dirname "$_src")/.." && pwd)"
else
  ROOT="$(pwd)"
fi
TMP=$(mktemp -d)

echo "Syncing agents from $REPO@$REF..."

git clone --depth=1 --branch "$REF" "$REPO" "$TMP" -q

if [ -d "$ROOT/.claude" ]; then
  echo "WARNING: $ROOT/.claude already exists and will be overwritten."
  printf "Continue? [y/N] "
  read -r answer
  if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    echo "Aborted."
    rm -rf "$TMP"
    exit 1
  fi
else
  mkdir -p "$ROOT/.claude"
fi

for item in agents rules skills template SETUP-GUIDE.md tech-config.md; do
  src="$TMP/.claude/$item"
  dst="$ROOT/.claude/$item"
  if [ -e "$src" ]; then
    rm -rf "$dst"
    cp -r "$src" "$dst"
    echo "  $item -> .claude/$item"
  else
    echo "  WARN: .claude/$item not found in upstream, skipping"
  fi
done

if [ -f "$TMP/README.md" ]; then
  cp "$TMP/README.md" "$ROOT/.claude/agents-guide.md"
  echo "  README.md -> .claude/agents-guide.md"
else
  echo "  WARN: README.md not found in upstream, skipping"
fi



if [ -f "$ROOT/CLAUDE.md" ]; then
  if ! grep -q "@.claude/tech-config.md" "$ROOT/CLAUDE.md"; then
    printf "\n@.claude/tech-config.md\n" >> "$ROOT/CLAUDE.md"
    echo "  @.claude/tech-config.md -> appended to CLAUDE.md"
  fi
else
  printf "@.claude/tech-config.md\n" > "$ROOT/CLAUDE.md"
  echo "  CLAUDE.md created with @.claude/tech-config.md"
fi

rm -rf "$TMP"
echo "Done."
