#!/bin/sh
# Verify documented Nix commands exist
# POSIX-compliant

set -e

# shellcheck source=utils.sh
. "$(dirname "$0")/utils.sh"

log_info "Verifying documented commands exist..."

errors=0

# Core commands from AGENTS.md documentation
# Each command is tested with --help to verify it exists
commands="
nix profile add --help
nix profile upgrade --help
nix develop --help
nix build --help
nix eval --help
nix store gc --help
nix path-info --help
nix derivation show --help
nix profile list --help
nix profile wipe-history --help
nix flake --help
nix-collect-garbage --dry-run
"

for cmd in $commands; do
	if $cmd >/dev/null 2>&1; then
		log_success "$cmd"
	else
		log_error "$cmd"
		errors=$((errors + 1))
	fi
done

if [ "$errors" -gt 0 ]; then
	die "$errors command(s) failed verification"
fi

log_success "All commands verified"
