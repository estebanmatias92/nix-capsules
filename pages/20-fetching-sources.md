# Nix Capsules 20: Fetching Sources

## Introduction

Welcome to the twentieth and final Nix capsule. In the previous capsule, we explored multiple outputs. In this capsule, we'll explore **fetching sources**—how to download and verify sources using fetchurl, fetchFromGitHub, and other fetch helpers.

Understanding how to fetch sources is essential for creating reproducible packages from external code.

## The Fetching Problem

When packaging software, you need to:
1. Download source code from the internet
2. Verify the download hasn't been tampered with
3. Ensure reproducibility (same URL = same content = same path)

Nix solves this with **fixed-output derivations**—downloaders that verify content hashes.

## fetchurl

The simplest fetcher for HTTP/HTTPS URLs:

```nix
stdenv.mkDerivation {
  name = "hello-2.12.1";

  src = fetchurl {
    url = "mirror://gnu/hello/hello-2.12.1.tar.gz";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
}
```

### Required Attributes

| Attribute | Purpose |
|-----------|---------|
| `url` | URL to download |
| `sha256` | Expected SHA-256 hash (base32-encoded) |

### Computing the Hash

```bash
# Download the file first
curl -L https://example.com/file.tar.gz -o file.tar.gz

# Compute hash in correct format
nix hash-file --base32 file.tar.gz
# sha256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
```

### URL Mirrors

The `mirror://` scheme supports multiple mirrors:

```nix
fetchurl {
  url = "mirror://gnu/hello/hello-2.12.1.tar.gz";
  sha256 = "sha256-...";
}
```

Nix tries multiple GNU mirrors automatically.

## fetchzip

For ZIP archives:

```nix
fetchzip {
  url = "https://example.com/project.zip";
  sha256 = "sha256-...";
}
```

Automatically extracts the archive contents.

## fetchFromGitHub

For GitHub repositories:

```nix
fetchFromGitHub {
  owner = "NixOS";
  repo = "nixpkgs";
  rev = "23.11";
  sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
}
```

### Attributes

| Attribute | Purpose |
|-----------|---------|
| `owner` | Repository owner |
| `repo` | Repository name |
| `rev` | Git commit SHA or tag |
| `sha256` | Expected hash |

### Using Refs

```nix
fetchFromGitHub {
  owner = "owner";
  repo = "repo";
  rev = "v1.2.3";  # Tag or commit
  sha256 = "sha256-...";
}
```

### Private Repositories

Use OAuth tokens:

```bash
# Set environment variable
export NIX_GITHUB_TOKEN="ghp_..."
```

```nix
fetchFromGitHub {
  owner = "owner";
  repo = "private-repo";
  rev = "main";
  sha256 = "sha256-...";
  # Token from environment
}
```

## fetchFromGitea

For Gitea instances:

```nix
fetchFromGitea {
  owner = "owner";
  repo = "repo";
  rev = "v1.0.0";
  sha256 = "sha256-...";
  domain = "codeberg.org";  # Gitea instance
}
```

## fetchFromGitLab

For GitLab projects:

```nix
fetchFromGitLab {
  owner = "owner";
  repo = "repo";
  rev = "v1.0.0";
  sha256 = "sha256-...";
  # Optional: domain = "gitlab.com";
}
```

## fetchTarball

Generic tarball fetcher:

```nix
fetchTarball {
  url = "https://example.com/archive.tar.gz";
  sha256 = "sha256-...";
}
```

## fetchPip

For Python packages:

```nix
fetchPip {
  pname = "requests";
  version = "2.31.0";
  hash = "sha256-...";
}
```

## Hash Formats

### Base32 (for sha256 in fetchers)

```bash
nix hash-file --base32 file.tar.gz
# Output: sha256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
```

### Base16 (hex)

```bash
nix hash-file file.tar.gz
# Output: sha256:deadbeef...
```

### In Your Code

```nix
# Use base32 format (required for fetchurl)
sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

# Or with sha256: prefix
sha256 = "sha256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
```

### Wrong Format Error

If you get the hash format wrong:

```
hash mismatch in downloaded file
```

Recompute with correct format:

```bash
nix hash-file --base32 ./downloaded-file
```

## Immutable URLs

Fetchers produce **fixed-output derivations**:

```nix
# Even if the URL changes, the hash stays the same
# Path is based on the hash, not the URL

fetchurl {
  url = "https://example.com/file.tar.gz";
  sha256 = "sha256-...";  # This determines the path
}
```

### URL vs Hash

| What | Determines Path |
|------|-----------------|
| Input-addressed | URL, builder, all inputs |
| Fixed-output | Only the declared `sha256` |

This means:
- URL can go offline → path still valid (cached)
- Content must match hash → tampering detected

## Offline Builds

Fixed-output derivations can be built offline if cached:

```bash
# Build from cache
nix build .#package

# Offline mode (fail if not cached)
nix build --offline .#package
```

## Using fetchers in Expressions

### Simple Package

```nix
{ stdenv, fetchurl }:

stdenv.mkDerivation {
  name = "hello-2.12.1";

  src = fetchurl {
    url = "mirror://gnu/hello/hello-2.12.1.tar.gz";
    sha256 = "sha256-tQbjQY2vY/5v3p9I4F/0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
}
```

### With Unpack Phase

```nix
{ stdenv, fetchzip }:

stdenv.mkDerivation {
  name = "myproject";

  src = fetchzip {
    url = "https://github.com/owner/repo/archive/refs/tags/v1.0.zip";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  unpackPhase = ''
    unzip -q $src
    mv repo-* source
  '';

  installPhase = ''
    cd source
    make install
  '';
}
```

### Multiple Sources

```nix
stdenv.mkDerivation {
  name = "mypackage";

  srcs = [
    (fetchurl {
      url = "https://example.com/main.tar.gz";
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    })
    (fetchurl {
      url = "https://example.com/data.tar.gz";
      sha256 = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";
    })
  ];

  unpackPhase = ''
    tar -xf $src
    tar -xf $srcs
  '';
}
```

## Fetching Private Sources

### SSH for Git

```nix
fetchgit {
  url = "git@github.com:owner/repo.git";
  rev = "main";
  sha256 = "sha256-...";
  # Uses SSH keys from ssh-agent
}
```

### With Authentication

```bash
# Set up credentials
export NIX_GITHUB_TOKEN="ghp_..."
```

```nix
fetchFromGitHub {
  owner = "owner";
  repo = "private-repo";
  rev = "main";
  sha256 = "sha256-...";
  # Token from NIX_GITHUB_TOKEN
}
```

## Verification

### After Download

```bash
# Build and verify
nix build .#package

# Check the path
nix path-info /nix/store/*-hello-*

# Verify hash manually
nix hash-path --base32 /nix/store/*-hello-*
```

### Debugging Fetch Failures

```bash
# Verbose output
nix build .#package -vvvv

# Check network
curl -I https://example.com/file.tar.gz

# Verify hash locally
nix hash-file --base32 downloaded-file
```

## Best Practices

### 1. Always Include Hash

Never omit the hash—even for testing:

```nix
# BAD - will fail
fetchurl {
  url = "https://...";
  # sha256 = "...";
}

# GOOD - even for testing
fetchurl {
  url = "https://...";
  sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
}
```

### 2. Use Stable URLs

Prefer stable archive URLs over dynamic ones:

```nix
# GOOD - stable archive URL
fetchurl {
  url = "https://github.com/owner/repo/archive/v1.0.0.tar.gz";
  sha256 = "...";
}

# Avoid - tag URL can change
fetchurl {
  url = "https://github.com/owner/repo/archive/latest.tar.gz";
  sha256 = "...";
}
```

### 3. Compute Hashes Correctly

```bash
# Correct method
nix hash-file --base32 downloaded-file

# Wrong - wrong format
nix hash-file downloaded-file  # base16, not base32
```

### 4. Document Sources

Comment your fetchers:

```nix
# From: https://example.com/source-1.0.tar.gz
# Checksum: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
src = fetchurl {
  url = "https://example.com/source-1.0.tar.gz";
  sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
};
```

## Common Patterns

### Pattern 1: GitHub Archive

```nix
fetchFromGitHub {
  owner = "owner";
  repo = "repo";
  rev = "v2.0.0";
  sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
}
```

### Pattern 2: PyPI Package

```nix
fetchPip {
  pname = "requests";
  version = "2.31.0";
  hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
}
```

### Pattern 3: Multiple Sources

```nix
stdenv.mkDerivation {
  name = "mypackage";

  srcs = [
    (fetchurl {
      url = "https://example.com/main-v1.0.tar.gz";
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    })
    (fetchurl {
      url = "https://example.com/data-v1.0.tar.gz";
      sha256 = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";
    })
  ];

  unpackPhase = ''
    tar -xf $src
    tar -xf $srcs
  '';
}
```

## Troubleshooting

### Hash Mismatch

```
hash mismatch in downloaded file
```

Fix:

```bash
# Download file
curl -L https://example.com/file.tar.gz -o file.tar.gz

# Get correct hash
nix hash-file --base32 file.tar.gz

# Update flake.nix with correct hash
```

### URL 404

```
404 Not Found
```

Check:
```bash
# Verify URL works
curl -I https://example.com/file.tar.gz

# Update URL if moved
```

### Network Issues

```bash
# Test connection
curl -I https://example.com

# Check proxy settings
env | grep -i proxy
```

## Summary

- Use `fetchurl` for HTTP/HTTPS, `fetchzip` for ZIP, `fetchFromGitHub` for GitHub
- Always provide the `sha256` hash—required for reproducibility
- Compute hashes with `nix hash-file --base32`
- Fetchers create fixed-output derivations (path based on hash)
- Use `fetchFromGitHub` with `owner`, `repo`, `rev`, and `sha256`
- Multiple sources use `srcs` array
- Private repos use SSH or tokens

---

## Congratulations!

You've completed the Nix Capsules series. You now understand:

- The Nix expression language (types, functions, imports)
- How derivations work and how to build packages
- Store mechanics and content-addressing
- Flake architecture and project structure
- Package composition patterns (inputs, callPackage, override)
- Garbage collection and profile management
- Nixpkgs configuration and overlays
- Dependency propagation and hooks
- Store internals and multiple outputs
- Fetching sources with proper verification

With this foundation, you're ready to:
- Create your own Nix packages
- Use flakes for project management
- Understand and modify nixpkgs
- Set up development environments with `nix develop`
- Build reproducible, declarative systems

Continue exploring the Nix ecosystem—the community is active and helpful!

```nix
# End of Nix Capsules

# For more information, see:
# - Nix Manual: https://nix.dev/manual/nix
# - Nixpkgs Manual: https://nixos.org/manual/nixpkgs
# - NixOS Wiki: https://nixos.org/wiki
# - Zero to Nix: https://zero-to-nix.com (for quick reference)
```
