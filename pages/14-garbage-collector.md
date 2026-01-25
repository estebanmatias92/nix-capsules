# Nix Capsules 14: The Garbage Collector

## Introduction

Welcome to the eleventh Nix capsule. In the previous capsule, we explored package composition patterns. Now we'll explore the **garbage collector**—Nix's mechanism for removing unused store paths and reclaiming disk space.

Everything in Nix goes to `/nix/store`. Over time, this can grow large. The garbage collector identifies and removes paths that are no longer needed.

## How Garbage Collection Works

Nix uses **GC roots** to determine what's still needed. A path is a GC root if:

- It's a user environment (`nix profile` generations)
- It's been explicitly added as a GC root
- It's referenced by another GC root

Everything else is eligible for collection.

## Listing GC Roots

```bash
# Show all GC roots (legacy command - no modern equivalent)
nix-store --gc --list-roots

# Or list GC root directory
ls /nix/var/nix/gcroot
```

Roots appear as symlinks in `/nix/var/nix/gcroot` or similar locations.

## Running the Garbage Collector

The unified `nix` command provides basic garbage collection:

```bash
# Collect garbage (moves to trash first)
nix store gc

# Just collect, don't delete
nix store gc --max-free $((10 * 1024**3))  # Keep 10GB free
```

For comprehensive cleanup including old profile generations, use `nix-collect-garbage`:

```bash
# Delete old generations and collect garbage (recommended approach)
nix-collect-garbage --delete-old

# Delete generations older than 30 days
nix-collect-garbage --delete-older-than 30d

# Preview what would be deleted
nix-collect-garbage --delete-old --dry-run
```

The `nix-collect-garbage` command is a wrapper that:

1. Removes old profile generations
2. Runs garbage collection to delete unreferenced paths

## Understanding Generations

Nix profiles track **generations**—each installation creates a new generation:

```bash
# List profile generations
nix profile history /nix/var/nix/profiles/default

# Or with the new CLI
nix profile list
```

Generations are automatically GC roots. Old generations keep old packages alive.

## Removing Old Generations

Modern Nix provides `nix profile wipe-history` for managing profile generations:

```bash
# Delete all old generations, keep current
nix profile wipe-history

# Delete generations older than 7 days
nix profile wipe-history --older-than 7d

# Preview what would be deleted
nix profile wipe-history --dry-run

# Specific profile
nix profile wipe-history --profile /nix/var/nix/profiles/default --older-than 30d
```

## Profile Management

Modern Nix uses `nix profile` for user environments:

```bash
# List installed packages
nix profile list

# History of changes
nix profile history

# Rollback to previous generation
nix profile rollback

# Rollback to specific generation
nix profile rollback --to 5
```

## Ephemeral Garbage Collection

Builds from flakes create temporary GC roots:

```bash
# Build without creating persistent GC root
nix build .#package --no-link

# Build and create GC root (default)
nix build .#package
```

The `result` symlink is a GC root. Remove it to allow collection.

## Finding Large Packages

Identify space hogs:

```bash
# List packages by size
nix path-info --json --all | jq 'map({path: .key, size: .value.narSize}) | sort_by(.size) | reverse | .[0:20]'

# Find packages not referenced by any profile (legacy command)
nix-store --gc --list-dead
```

## Pruning Unused Store Paths

For comprehensive cleanup, `nix-collect-garbage` handles all cleanup tasks:

```bash
# Combined cleanup (recommended)
nix-collect-garbage --delete-old

# Legacy commands (still available)
nix-store --gc --delete-dead    # Delete unreferenced paths
nix-store --gc --empty-trash    # Empty the trash
```

## The trash Directory

Deleted paths move to `/nix/store/trash` first:

```bash
# See what's in the trash
ls -la /nix/store/trash/

# Permanently delete trash contents
nix-store --gc --empty-trash
```

This prevents accidental deletion—if you realize you needed something, you can restore it before emptying the trash.

## Automatic GC Scheduling

Nix can run GC automatically:

```bash
# Check GC schedule
systemctl status nix-gc

# Configure in /etc/nix/nix.conf
# gc = true
# gc-interval = 7
```

On NixOS, configure in `configuration.nix`:

```nix
nix.gc = {
  enabled = true;
  interval = "7d";
  options = "--delete-older-than 30d";
};
```

## Managing Build Caches

Build results can accumulate:

```bash
# Clean build caches
nix-collect-garbage --delete-old

# Clear s3 binary caches
nix store delete --recursive s3://my-bucket/*
```

## Reproducibility Considerations

Be careful when deleting:

- **Don't delete** paths you're actively developing
- **Do delete** old package versions you're no longer using
- **Use** `nix-collect-garbage --delete-old` for effective cleanup

For reproducible systems, keep multiple generations for rollback capability.

## Summary

- GC roots mark paths as "in use"—everything else is garbage
- Use `nix-collect-garbage --delete-old` for comprehensive cleanup
- Use `nix profile wipe-history --older-than Nd` for time-based cleanup
- Use `nix store gc` for basic garbage collection only
- Profile generations are automatically GC roots
- The trash provides safety against accidental deletion

## Next Capsule

In the next capsule, we'll dive deep into **nixpkgs**—the central package collection that provides thousands of packages and utilities for Nix.

> **[Nix Capsules 15: Nixpkgs Deep Dive](./15-nixpkgs-deep-dive.md)**
