#!/bin/sh
# Verify documented Nix commands exist
# POSIX-compliant

set -e

# shellcheck source=utils.sh
. "$(dirname "$0")/utils.sh"

log_info "Verifying documented commands exist..."

errors=0

# Use a while loop with a Here-Doc to read line by line
while read -r cmd; do
    # Skip empty lines or lines starting with # (comments)
    case "$cmd" in 
        ""|\#*) continue ;; 
    esac

    # $cmd is unquoted here intentionally to allow word splitting of arguments
    # e.g., "nix profile add" becomes command: "nix", args: "profile", "add"
    if $cmd >/dev/null 2>&1; then
        log_success "$cmd"
    else
        log_error "$cmd"
        errors=$((errors + 1))
    fi
done <<EOF
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
EOF

if [ "$errors" -gt 0 ]; then
    die "$errors command(s) failed verification"
fi

log_success "All commands verified"