#!/bin/sh
# Verify nix-hash command works
# POSIX-compliant

set -e

# shellcheck source=utils.sh
. "$(dirname "$0")/utils.sh"

log_info "Testing nix-hash command..."

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

echo "test content" >"$tmpfile"
nix-hash --type sha256 --base32 "$tmpfile" >/dev/null

log_success "nix-hash works"
