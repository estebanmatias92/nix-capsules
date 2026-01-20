# Nix Capsules 18: Store Internals

## Introduction

In the previous capsule, we covered dependency propagation. Now we'll explore **store internals**—how Nix handles fixed-output derivations, content-addressable storage, and path resolution.

Understanding these internals helps with debugging, caching strategies, and advanced use cases.

## Fixed-Output Derivations Recap

Fixed-output derivations (FODs) have paths based on **declared content hashes**, not build inputs:

```nix
stdenv.mkDerivation {
  name = "mytarball";
  src = fetchurl {
    url = "https://example.com/file.tar.gz";
    sha256 = "abcdef...";  # Declared hash
  };
}
```

The path looks like:

```
/nix/store/sha256-abcdef1234567890...-file.tar.gz
#      └──────────────────┘
#         Declared hash (not content hash)
```

### FOD Characteristics

| Aspect | Behavior |
|--------|----------|
| Path computation | Based on declared `sha256` |
| Build requirement | Downloaded content must match hash |
| Reproducibility | Guaranteed (hash declared, not computed from download) |
| Caching | Cached by hash |

### Verifying FODs

```bash
# Build and verify
nix build .#mytarball

# Check the path
nix path-info /nix/store/*-file.tar.gz

# Verify hash
nix hash-file --base32 ./downloaded.tar.gz
```

## Content vs Input Addressing

### Input-Addressed Derivations (IAD)

Most packages are input-addressed:

```nix
derivation {
  name = "hello";
  system = "x86_64-linux";
  builder = "/nix/store/...-bash/bin/bash";
  args = [ ... ];
  src = ...;
  gcc = ...;
}
```

| Aspect | IAD Behavior |
|--------|--------------|
| Path hash | Based on `.drv` file content |
| Change trigger | Any input change |
| Cache key | Derivation inputs |

### Content-Addressed Derivations (CAD)

Modern Nix supports true content-addressing:

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

| Aspect | CAD Behavior |
|--------|--------------|
| Path hash | Based on output **content** |
| Change trigger | Output content change |
| Cache key | Output hash |
| Reproducibility | Guaranteed by content |

### Comparison

| Feature | Input-Addressed | Content-Addressed |
|---------|----------------|-------------------|
| Path depends on | Derivation inputs | Output content |
| Two identical builds | Same path | Same path |
| Rebuild on input change | Yes | No |
| Supported since | Always | Nix 2.18+ |

## Path Resolution

Nix resolves store paths through multiple mechanisms:

### 1. Direct References

Derivation attributes reference other derivations:

```nix
derivation {
  name = "mypackage";
  gcc = nixpkgs.gcc;  # Resolves to gcc's outPath
}
```

In the builder, `gcc` environment variable contains the store path.

### 2. String Interpolation

Paths in strings resolve to store paths:

```nix
"${nixpkgs.gcc}/bin/gcc"  # Resolves to /nix/store/...-gcc-*/bin/gcc
```

### 3. Attribute Access

Package sets resolve through attribute access:

```nix
nixpkgs.legacyPackages.x86_64-linux.hello
# Resolves to hello derivation
```

### 4. The Database

Nix maintains a SQLite database at `/nix/var/nix/db`:

```bash
# Query database (legacy)
nix-store -q --referrers /nix/store/*-hello*

# Modern equivalent
nix path-info --json /nix/store/*-hello* | jq
```

## The NAR Hash vs Store Path Hash

Two different hashes exist:

### NAR Hash

Hash of the **file contents** (NAR format):

```bash
# Hash of actual content
nix-hash --type sha256 --nar ./hello
# a1b2c3d4e5f6...
```

### Store Path Hash

Hash of the NAR hash **plus metadata**:

```bash
# Hash for path computation
nix-hash --type sha256 --truncate --base32 ./hello
# 3sg4bhqws9rx6a0b0z4q6r8c6v5m3w4x
```

### Why Two Hashes?

| Hash | Used For | Changes When |
|------|----------|--------------|
| NAR hash | Content verification | File contents change |
| Path hash | Store path | NAR hash changes OR metadata changes |

## Build References

During builds, Nix tracks:

### Input Derivations (inputDrvs)

```json
{
  "inputDrvs": {
    "/nix/store/...-gcc-13.2.0.drv": ["out"]
  }
}
```

### Input Sources (inputSrcs)

```json
{
  "inputSrcs": [
    "/nix/store/...-hello-2.12.1.tar.gz"
  ]
}
```

### Output References

```json
{
  "references": [
    "/nix/store/...-glibc-2.38"
  ]
}
```

### Referrers

What depends on this path:

```bash
# Show what depends on glibc
nix path-info --json /nix/store/*-glibc* | jq -r '.[0].referrers[]'
```

## Multiple Outputs

Nix supports derivations with multiple outputs:

```nix
stdenv.mkDerivation {
  name = "hello-2.12.1";

  outputs = [ "out" "doc" "dev" ];

  installPhase = ''
    mkdir -p $out $doc $dev
    cp hello $out/bin/
    cp -r man $doc/
    cp -r include $dev/
  '';
}
```

### Output Specification Syntax

| Syntax | Meaning |
|--------|---------|
| `outputs = ["out"];` | Single output named "out" |
| `outputs = ["out" "doc"];` | Two outputs |
| `outputs = ["dev" "out"];` | Order doesn't matter |

### Using Multiple Outputs

```nix
# Reference specific output
pkgs.hello.dev  # The dev output

# Default output
pkgs.hello      # Same as pkgs.hello.out
```

### Environment Variables

For output "out":
- `$out` → path to "out"
- `$outBin` → $out/bin
- `$outLib` → $out/lib

For output "doc":
- `$doc` → path to "doc"

### Separating Outputs

Packages with multiple outputs set `separately`:

```nix
stdenv.mkDerivation {
  name = "libfoo";

  outputs = ["out" "dev"];

  dontBuildDev = true;
}
```

## Runtime vs Build-time References

### Build-time References

Paths referenced during the build:

```bash
# From derivation
nix derivation show /nix/store/...-mypackage.drv | jq '.[].inputDrvs'
```

### Runtime References

Paths the output actually uses:

```bash
# From runtime
nix path-info --json /nix/store/...-mypackage | jq '.[].references'
```

### Common Mismatch

```nix
# Builder references /usr/include (not a store path)
# This causes build-time issues but won't be in runtime references
```

## Derivation Metadata

Nix stores metadata in `$out/nix-support/`:

```
$nix-support/
├── propagated-build-inputs    # propagatedBuildInputs
├── setup-hook                 # setup hook script
└── user-environment-hook      # for nix-env
```

### Setup Hooks

Setup hooks run automatically when a package is included:

```bash
# In $out/nix-support/setup-hook.sh
addToSearchPath PATH $out/bin
```

## Content Addressing in Practice

### Checking Content Hash

```bash
# Get the output path
result=$(nix path-info /nix/store/*-hello)

# Hash the content
nix hash-path --base32 "$result"
```

### Comparing Hashes

```bash
# Expected hash from flake.lock
echo "sha256-abc123..."

# Actual hash
nix hash-path --base32 /nix/store/*-hello

# Match?
```

## Troubleshooting

### "derivation has wrong output"

The `.drv` file doesn't match what's in the store:

```bash
# Check derivation
nix derivation show /nix/store/...-package.drv

# Rebuild
nix build .#package --rebuild
```

### "output path conflict"

Two derivations want the same path:

```bash
# Check what's in the store
ls /nix/store/*-name-*

# Remove old
nix store delete /nix/store/...-name-*
```

### "cycle detected"

A package depends on itself:

```bash
# Find the cycle
nix why-depends .#package .#package
```

## Summary

- Fixed-output derivations use declared hashes for reproducibility
- Content-addressed derivations depend on output content
- Two hashes exist: NAR hash (content) and path hash (metadata)
- Multiple outputs enable splitting packages into sub-paths
- Runtime references are auto-discovered from built outputs
- Setup hooks enable automatic environment configuration
- The database tracks all references and referrers

## Next Capsule

In the next capsule, we'll explore **multiple outputs**—how to split packages into separate outputs for efficient storage and deployment.

```nix
# Next: ./pages/19-multiple-outputs.md
```
