#!/bin/sh
# Check for deprecated command usage in documentation
# POSIX-compliant

set -e

# shellcheck source=utils.sh
. "$(dirname "$0")/utils.sh"

PAGES_DIR="${1:-pages}"

log_info "Checking for deprecated command usage..."

warnings=0

# These commands should be marked as legacy in documentation
# Patterns to check for (soft check - just warns)
deprecated_patterns="
nix-store -q --references
nix store query
nix store list
"

for pattern in $deprecated_patterns; do
	if grep -rq "$pattern" "$PAGES_DIR"/*.md 2>/dev/null; then
		log_warn "Found '$pattern' - ensure it has legacy note"
		warnings=$((warnings + 1))
	fi
done

log_success "Deprecated pattern check complete ($warnings warnings)"
