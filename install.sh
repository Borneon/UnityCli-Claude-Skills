#!/usr/bin/env bash
# Unity-MCP skill kurucu (macOS / Linux)
# Bu betiği çalıştır: ./install.sh   (gerekirse önce: chmod +x install.sh)
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.claude/skills"

if [ ! -d "$DIR/unity-mcp" ]; then
  echo "HATA: yanında 'unity-mcp' klasörü yok. Zip'i tamamen açtın mı?" >&2
  exit 1
fi

mkdir -p "$DEST"

if [ -e "$DEST/unity-mcp" ]; then
  echo "Not: $DEST/unity-mcp zaten var, üzerine yazılıyor."
  rm -rf "$DEST/unity-mcp"
fi

cp -R "$DIR/unity-mcp" "$DEST/unity-mcp"

echo "✓ unity-mcp skill kuruldu → $DEST/unity-mcp"
echo "  Claude Code'u yeniden başlat, sonra 'unity-mcp' skill'i kullanılabilir olur"
echo "  (ya da /unity-mcp ile elle çağır)."
