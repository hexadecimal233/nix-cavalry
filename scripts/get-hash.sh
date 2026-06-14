#!/usr/bin/env bash
# ──────────────────────────────────────────────────────
# Maintainer tool — not for end users.
# Updates the SRI hash in pkgs/cavalry/default.nix when
# Cavalry publishes a new MSI at the `latest` URL.
# ──────────────────────────────────────────────────────
set -euo pipefail

cd "$(dirname "$0")/.."

PKG="pkgs/cavalry/default.nix"
URL="https://cavalry.studio/downloads/latest/Cavalry.msi"

# Guard: only run in the nix-cavalry repo root.
[ -f "$PKG" ] || { echo "FATAL: run from nix-cavalry repo root"; exit 1; }

echo "Fetching $URL …"

# Download and compute the Nix base-32 hash.
NIX_HASH=$(nix-prefetch-url \
  --name "Cavalry.msi" \
  "$URL" \
  2>/dev/null)

# Convert to SRI format (sha256-<base64>).
SRI=$(nix hash convert --hash-algo sha256 --to sri "$NIX_HASH")
echo "New hash: $SRI"

# Read current hash from the package file.
CURRENT=$(grep -oP 'hash = "\Ksha256-[^"]+' "$PKG" || true)

if [ "$SRI" = "$CURRENT" ]; then
  echo "Hash unchanged — nothing to do."
  exit 0
fi

# Update in-place (macOS-compatible sed).
sed -i '' \
  "s|hash = \"sha256-[^\"]*\"|hash = \"$SRI\"|" \
  "$PKG"

echo "Updated $PKG"
echo
echo "Verify the change:"
echo "  nix-instantiate --parse --strict $PKG"
