#!/bin/sh
# Check for broken internal links in capsule pages
# POSIX-compliant

set -e

# shellcheck source=utils.sh
. "$(dirname "$0")/utils.sh"

PAGES_DIR="${1:-pages}"

log_info "Checking for broken internal links..."

errors=0

for file in "$PAGES_DIR"/*.md; do
	[ -f "$file" ] || continue

	dir=$(dirname "$file")

	# Extract markdown links to .md files: [text](./XX-topic.md)
	# grep returns: ](./XX-topic.md) or empty if no matches
	while IFS= read -r link || [ -n "$link" ]; do
		# Skip empty lines
		[ -n "$link" ] || continue

		# Strip leading "](" (2 chars) and trailing ")" (1 char)
		link="${link#??}"
		link="${link%?}"

		# Remove leading "./" if present
		clean_path="${link#./}"

		# Construct the full path to check
		target="$dir/$clean_path"

		if [ ! -f "$target" ]; then
			log_error "Broken link in $file: $link"
			errors=$((errors + 1))
		fi
	done <<EOF
$(grep -oE '\]\([^)]+\.md\)' "$file" 2>/dev/null)
EOF
done

if [ "$errors" -gt 0 ]; then
	die "Found $errors broken link(s)"
fi

log_success "All internal links are valid"
