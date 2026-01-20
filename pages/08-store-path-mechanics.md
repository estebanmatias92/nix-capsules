# Nix Capsules 8: Store Path Mechanics

## Introduction

In the previous capsule, we wrote our first derivation. Now we'll understand **how Nix computes store paths**—the mechanics behind content-addressing, hashing, and why paths look the way they do.

Understanding store path mechanics is essential for debugging, caching, and grasping why Nix achieves reproducibility.

## The NAR Format

Nix uses **NAR** (Nix ARchive) as its deterministic serialization format. NAR replaces tar for several reasons:

### NAR Characteristics

- **Sorted file order**: Entries are always sorted alphabetically
- **Consistent metadata**: Permissions and types are preserved, but timestamps are zeroed
- **No owner info**: User and group IDs are not stored
- **Content-addressed**: The NAR hash depends only on file contents

### NAR Structure

```bash
(type) directory
│
├── (type) regular file "hello.c" (contents)
│
├── (type) symlink "hello" -> "hello.c"
│
└── (type) directory "src"
    └── (type) regular file "main.c" (contents)
```

### Creating NAR Archives

```bash
# Create a NAR (legacy command, still works)
nix-store --dump /path/to/dir > output.nar

# Extract a NAR (legacy command, still works)
nix-store --import < output.nar
```

Modern Nix uses NAR internally for content hashing.

## Hashing Process

The store path hash goes through several steps:

```bash
┌─────────────┐
│  Contents   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  NAR format │  (deterministic serialization)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  SHA-256    │  (160-bit output)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Base-32    │  (32 characters)
└──────┬──────┘
       │
       ▼
┌─────────────────────────────┐
│ /nix/store/[hash]-name      │  (final path)
└─────────────────────────────┘
```

### Base-32 Encoding

Nix uses a custom base-32 alphabet:

```bash
0123456789abcdfghijklmnpqrsvwxyz
         ↑
         No: e, o, u, B, I, O, etc.
```

This avoids ambiguous characters and creates valid filenames.

```bash
# Example: SHA-256 hash
sha256: 2bfee9d7d0eea2e8ad5e8b2a9fcfd3a1c4e7b6d9f0a8c2e5b1d3c7f9a8e2d5

# Becomes (base-32, truncated):
3sg4bhqws9rx6a0b0z4q6r8c6v5m3w4x
```

## Input-Addressed vs Content-Addressed

Nix uses two addressing schemes:

### Input-Addressed Paths

Most derivations are **input-addressed**—the hash depends on inputs:

```nix
derivation {
  name = "hello";
  system = "x86_64-linux";
  builder = "/nix/store/...-bash-5.2/bin/bash";
  args = [ ./builder.sh ];
  src = ./hello.c;
}
```

The path hash includes:

- The `.drv` file content (builder, args, dependencies)
- All input derivations (recursively)
- System and architecture

If any input changes, the output path changes.

### Content-Addressed Paths

For sources with known hashes, Nix uses **content-addressing**:

```nix
stdenv.mkDerivation {
  name = "mytarball";
  src = fetchurl {
    url = "https://example.com/file.tar.gz";
    sha256 = "abcdef...";
  };
}
```

The path depends on:

- The declared `sha256` (not the actual download)
- The derivation name

Even if the source changes upstream, Nix uses the declared hash.

## Fixed-Output Derivations

The `fetchurl`, `fetchFromGitHub`, and similar functions create **fixed-output derivations**:

```nix
fetchurl {
  url = "https://example.com/file.tar.gz";
  sha256 = "sha256-abc123...";
}
```

These are special because:

- The output path is computed from the **declared hash**
- Nix verifies the downloaded content matches the hash
- Two identical sources always get the same path

### Why Fixed Outputs?

Without fixed outputs, the path would change if:

- The URL server modifies the file
- The file is served with different timestamps
- The server is unavailable during build

Fixed outputs guarantee reproducibility.

## Viewing Derivation Outputs

Check how Nix computes a path:

```bash
# Show derivation details
nix derivation show /nix/store/...-hello-2.12.1.drv
```

```json
{
  "/nix/store/...-hello-2.12.1.drv": {
    "outputs": {
      "out": {
        "path": "/nix/store/3sg4bhqws9rx6a0b0z4q6r8c6v5m3w4x-hello-2.12.1"
      }
    },
    "inputDrvs": { ... },
    "inputSrcs": [ ... ],
    "platform": "x86_64-linux",
    "builder": "/nix/store/...-bash-5.2/bin/bash",
    "args": [ ... ],
    "env": {
      "name": "hello-2.12.1",
      "out": "/nix/store/...-hello-2.12.1",
      "src": "/nix/store/...-hello-2.12.1.tar.gz",
      "system": "x86_64-linux"
    }
  }
}
```

The `out.path` field shows the computed store path.

## Computing Hashes Manually

For debugging, compute hashes manually:

```bash
# Hash a file (base32)
nix-hash --type sha256 --base32 ./file

# Hash in NAR format
nix-hash --type sha256 --base32 --nar ./file

# Truncate to 160 bits (store path length)
nix-hash --type sha256 --truncate --base32 ./file
```

### Complete Path Computation

```bash
# Step 1: Hash the source file
nix-hash --type sha256 --base32 ./hello.c
# a1b2c3d4e5f6...

# Step 2: Create input for path hash
echo -n "source:sha256:a1b2c3d4e5f6...:path:hello.c" > input.txt

# Step 3: Hash for final path
nix-hash --type sha256 --truncate --base32 input.txt
# 3sg4bhqws9rx6a0b0z4q6r8c6v5m3w4x

# Step 4: Final path
/nix/store/3sg4bhqws9rx6a0b0z4q6r8c6v5m3w4x-hello.c
```

## Store Path Validation

Valid store path characters:

```nix
Allowed:  a-z, 0-9, -, _, .
Forbidden: A-Z, spaces, special chars
```

This ensures paths work on all filesystems.

```bash
# These work:
/nix/store/abc123-hello-2.12.1/
/nix/store/abc123-hello_world-2.12.1/
/nix/store/abc123-hello-2.12.1.1/

# These don't:
/nix/store/abc123-Hello-2.12.1/  # Uppercase
/nix/store/abc123-hello world/   # Space
```

## Content-Addressable Futures

Modern Nix (2.18+) supports **content-addressable derivations** where outputs are addressed by their content:

```nix
{
  outputs = {
    out = {
      type = "derivation";
      output = "out";
      inputDrvs = { };
      inputSrcs = [ ];
      system = "x86_64-linux";
      builder = "...";
      args = [ ];
      env = { };
    };
  };
}
```

This means:

- The path hash depends on **output content**, not inputs
- If outputs are identical, paths are identical
- Better caching and deduplication

## Querying Store Paths

Use modern commands to explore paths:

```bash
# List store contents (requires specific store path)
nix store ls /nix/store/i3zw7h6pg3n9r5i63iyqxrapa70i4v5w-hello-2.12.2

# Or use standard bash ls
ls /nix/store | grep hello | head -5

# Find a specific package
ls /nix/store | grep hello

# Show full details
ls -ld /nix/store/*-hello-*
```

## Why This Matters

Understanding store path mechanics helps you:

| Scenario | Understanding Helps |
| -------- | ------------------- |
| Debugging build issues | Trace why paths change |
| Binary caches | Understand cache keys |
| Reproducibility | Know why same inputs = same outputs |
| Cleanup | Identify what's safe to delete |
| Cross-compilation | Understand platform in paths |

## Common Patterns

### Pattern 1: Source Paths

Source files get paths based on content:

```bash
/nix/store/a1b2c3d4-hello.c        # Hash of hello.c
/nix/store/e5f6g7h8i9-hello.c      # Different file = different hash
```

### Pattern 2: Derivation Outputs

Built packages include derivation hash:

```bash
/nix/store/3sg4bhqws9rx6a0b0z4q6r8c6v5m3w4x-hello-2.12.1/
#                                           └──────────┘
#                                           Name + version
```

### Pattern 3: Fixed Outputs

Fetched sources use declared hash:

```bash
/nix/store/sha256-abc123def456...-hello-2.12.1.tar.gz
#                 └─────────────┘
#                  Declared hash
```

## Summary

- NAR format provides deterministic serialization
- SHA-256 + Base-32 produces store path hashes
- Input-addressed: hash depends on derivation inputs
- Content-addressed: hash depends on output content
- Fixed-output derivations use declared hashes for reproducibility
- Modern Nix supports full content-addressable derivations
- Store path rules ensure valid filenames across systems

## Next Capsule

In the next capsule, we'll explore **stdenv**—the standard environment that provides build utilities and phases for most Nix packages.

> [**Nix Capsules 9: Building with stdenv**](./09-building-with-stdenv.md)
