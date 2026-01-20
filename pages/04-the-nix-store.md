# Nix Capsules 4: The Nix Store

## Introduction

In the previous capsule, we installed Nix and ran our first commands. Now we'll explore the **Nix Store**—the heart of how Nix achieves reproducibility.

The Nix Store (`/nix/store`) is where everything lives. Unlike traditional package managers that install files to `/usr/bin`, Nix stores each package in its own isolated directory with a unique hash.

## The Store Path Structure

Every item in the Nix Store follows this pattern:

```bash
/nix/store/[base32-hash]-[package-name]-[version]/
```

Examples:

```bash
/nix/store/3sg4bhqws9rx6a0b0z4q6r8c6v5m3w4x-hello-2.12.1/
/nix/store/naxm4k6xz9fh0v3b2p8c4r7z0y5q1d9s-glibc-2.38/
/nix/store/zyxw9876abcd1234efgh5678ijkl9012-gcc-13.2.0/
```

## What Makes This Special

### 1. Immutable Packages

Nothing in `/nix/store` is ever modified. When you "upgrade" a package, Nix creates a **new** store path with a different hash. The old version remains untouched.

This means:

- Multiple versions coexist without conflict
- Rolling back is instant—just change a symlink
- Dependencies are guaranteed to match exactly what was built

### 2. Content-Addressing

The hash isn't random—it's computed from the **content** of what Nix builds. Two identical derivations produce the same hash.

```bash
# Same source + same build = same hash
/nix/store/3sg4bhqws9rx6a0b0z4q6r8c6v5m3w4x-hello-2.12.1/
```

This enables:

- **Binary caching**: Nix knows if a path is already built
- **Garbage collection**: Unused paths can be safely deleted
- **Reproducibility**: Same inputs always produce same outputs

### 3. Self-Contained Directories

Each store path contains everything the package needs:

```bash
/nix/store/...-hello-2.12.1/
├──  bin
│   └── 󰡯 hello                     # The hello binary
└──  share
    ├──  info
    ├──  locale
    └──  man
```

The binary references only paths within its own store directory.

## How Hashes Are Computed

Nix uses a multi-step process to compute store path hashes:

1. **NAR serialization**: Nix creates a NAR (Nix ARchive)—a deterministic format
2. **SHA-256 hashing**: The NAR is hashed
3. **Base-32 encoding**: The hash is encoded in Nix's custom base-32 alphabet
4. **Path construction**: The encoded hash is combined with the name

```bash
# Conceptual process
content → NAR format → SHA-256 → base32 → /nix/store/[hash]-name
```

The base-32 encoding uses lowercase letters and digits, ensuring valid filenames.

## Verifying Store Paths

Explore your local store:

```bash
# List store contents
ls /nix/store | head -20

# Find a specific package
ls /nix/store | grep hello

# Show full details
ls -ld /nix/store/*-hello-*
```

## The Role of Hashes

The hash serves multiple purposes:

| Purpose                 | How Hash Helps                     |
| ----------------------- | ---------------------------------- |
| **Uniqueness**          | Different content = different hash |
| **Identification**      | Hash identifies exact derivation   |
| **Caching**             | Same hash = already built = reuse  |
| **Dependency tracking** | References stored in derivation    |

Consider what happens when `openssl` is updated:

```bash
Old: /nix/store/abc123-openssl-1.1.1k/     (unchanged)
New: /nix/store/def456-openssl-3.0.0/      (new path)
```

Any package depending on OpenSSL will reference the specific hash it was built with. Old packages keep working with the old OpenSSL.

## Store Path Anatomy

Breaking down a store path:

```bash
/nix/store/3sg4bhqws9rx6a0b0z4q6r8c6v5m3w4x-hello-2.12.1/
└──┬──────┘ └────────┬────────────────────┘ └──┬───────┘
   │                 │                         └── Human-readable name + version
   │                 └── Base-32 encoded hash of content
   └── Fixed prefix
```

Components:

- `/nix/store/`: Fixed prefix
- `3sg4bhqws9rx6a0b0z4q6r8c6v5m3w4x`: 32-character base-32 hash
- `hello-2.12.1`: Human-readable name (no spaces, special chars)

## Immutable Means Safe

Because store paths are immutable:

```bash
# This will fail - you can't write to /nix/store
echo "modified" > /nix/store/*-hello-2.12.1/bin/hello

# Permission denied - only nix-daemon can write
```

Nix protects your system from accidental or malicious modification. Changes require going through Nix's build system.

## Store Permissions

The store has special permissions:

```bash
# Store is owned by nix-daemon
ls -la /nix/store | head -5
# drwxr-xr-x root nix  /nix/store

# Regular users can read but not write
cat /nix/store/*-hello-2.12.1/bin/hello  # Works
echo "test" > /nix/store/*-hello-2.12.1/test  # Fails
```

Only the Nix daemon (running as `nixbld*` users) can modify the store.

## Summary

- The Nix Store (`/nix/store`) is where packages live
- Each package has a unique path with a content-based hash
- Store paths are immutable—upgrades create new paths
- Hashes enable caching, garbage collection, and reproducibility
- Multiple versions coexist without conflict
- Only the Nix daemon can write to the store

## Next Capsule

In the next capsule, we'll explore the **Nix expression language**—the syntax for writing Nix code, including types, functions, and data structures.

```nix
# Next: ./05-basics-of-language.md
```
