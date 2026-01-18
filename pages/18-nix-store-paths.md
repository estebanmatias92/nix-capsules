# Nix Capsules 18: Nix Store Paths

## Introduction

Welcome to the eighteenth Nix capsule. In the previous capsule, we overrode packages in nixpkgs. Now we'll explore **Nix store paths**—how Nix computes the unique paths where build outputs are stored in `/nix/store`.

Understanding store paths helps with debugging, caching, and content-addressable storage.

## Store Path Structure

Store paths follow this pattern:

```
/nix/store/[hash]-[name]
```

Examples:
- `/nix/store/3sg4bhqws9rx6a0b0z4q6r8c6v5m3w4x-hello-2.12.1`
- `/nix/store/naxm4k6xz9fh0v3b2p8c4r7z0y5q1d9s-glibc-2.38`

The hash ensures uniqueness and enables content-addressing.

## How Hashes Are Computed

Nix uses a multi-step process:

1. **Serialize** the input to a NAR (Nix ARchive) format
2. **Hash** the NAR with SHA-256
3. **Encode** the hash in base-32 (Nix's custom encoding)
4. **Construct** the final path with name

## NAR Format

NAR is Nix's deterministic archive format—it replaces tar for:
- Sorted file order
- Consistent metadata
- No timestamps or owner info

Create a NAR (legacy command):

```bash
nix-store --dump /path/to/dir > file.nar
```

List NAR contents (legacy command):

```bash
nix-store --import < file.nar
```

## Computing Store Paths Manually

For source files (legacy commands):

```bash
# Hash the NAR
nix-hash --type sha256 --base32 ./myfile

# Add the "source:" prefix and type
echo -n "source:sha256:HASH:path:myfile" > input.txt

# Hash again for final path
nix-hash --type sha256 --truncate --base32 input.txt
```

## Output Paths (Derivation Outputs)

Output paths depend on the `.drv` file content:

```bash
# Show derivation output path
nix derivation show /nix/store/...-package.drv
```

The hash includes:
- All input derivations (recursively)
- The builder script
- System and architecture
- Environment variables

## Fixed-Output Derivations

For sources with known hashes (like tarballs), use fixed outputs:

```nix
stdenv.mkDerivation {
  name = "mytarball";
  src = fetchurl {
    url = "https://example.com/file.tar.gz";
    sha256 = "abcdef...";
  };
}
```

The store path is computed from the fixed hash, not the derivation inputs.

## Content-Addressable Store Paths

Modern Nix supports **content-addressable** derivation outputs:

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

These paths depend on the actual output content, not the inputs.

## Store Path Queries

Find paths in the store:

```bash
# Find by name
nix store ls /nix/store | grep hello

# Find by output path and show references
nix path-info --json /nix/store/...-hello | jq -r '.[].references[]'
```

## Valid Store Path Characters

Store paths use:
- Lowercase letters (a-z)
- Digits (0-9)
- Hyphens (-), underscores (_), periods (.)

No uppercase, spaces, or special characters.

## Copying Between Stores

Copy store paths between machines:

```bash
# Copy a specific path
nix copy --to ssh://user@host /nix/store/...-hello

# Copy all dependencies
nix copy --to ssh://user@host --derivation /nix/store/...-hello.drv
```

## Understanding Hash Collisions

The base-32 encoding uses 5 bits per character, so 32 characters = 160 bits of SHA-256. Hash collisions are effectively impossible.

## NAR vs Store Hash

The NAR hash differs from the store path hash:
- NAR hash: Hash of the file contents (what you get from `nix-hash`)
- Store path hash: Hash of the NAR hash plus metadata

This is why adding a file changes both hashes.

## Summary

- Store paths follow `/nix/store/[hash]-[name]`
- NAR format ensures deterministic serialization
- Output paths depend on derivation inputs
- Fixed-output paths use declared content hashes
- Content-addressable derivations use output content for paths
- Use `nix store` commands to query and manage paths

## Next Capsule

In the next capsule, we'll explore **stdenv**—the standard environment that provides build utilities and phases for most Nix packages.

```nix
# Next: ./pages/19-fundamentals-of-stdenv.md
```
