# Common shell utilities for Nix Capsules CI scripts
# POSIX-compliant (run with /bin/sh)

# Logging functions
log_info() {
	printf '%s\n' "ℹ $*"
}

log_success() {
	printf '%s\n' "✓ $*"
}

log_error() {
	printf '%s\n' "✗ $*" >&2
}

log_warn() {
	printf '%s\n' "⚠ $*"
}

# Check if a command exists
require_command() {
	command -v "$1" >/dev/null 2>&1
}

# Exit with error message
die() {
	log_error "$*"
	exit 1
}

# Run a command and exit on failure
run_or_die() {
	if ! "$@"; then
		die "Command failed: $*"
	fi
}

# Count files matching a glob pattern
count_files() {
	set -- "$1"/*
	case $1 in
	*/\*) set -- ;;
	esac
	echo $#
}

# Get the directory containing this script
get_script_dir() {
	cd "$(dirname "$0")" && pwd
}

# Get the project root directory
get_project_root() {
	cd "$(dirname "$0")/../.." && pwd
}
