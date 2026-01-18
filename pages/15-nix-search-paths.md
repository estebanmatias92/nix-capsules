# Nix Capsules 15: Nix Search Paths

## Introduction

Welcome to the fifteenth Nix capsule. In the previous capsule, we used the override pattern to customize packages. Now we'll explore **Nix search paths**—how Nix locates expressions like `<nixpkgs>` and how to configure them.

## The NIX_PATH Environment Variable

`NIX_PATH` tells Nix where to find expressions referenced with angle brackets:

```bash
echo $NIX_PATH
# nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixpkgs
```

The syntax is similar to `PATH`: paths separated by colons, with optional name prefixes.

## Using Angle Bracket Syntax

Reference paths in Nix expressions:

```nix
# Import nixpkgs from NIX_PATH
pkgs = import <nixpkgs> { };

# Same as
pkgs = import "/nix/var/nix/profiles/per-user/root/channels/nixpkgs";
```

## Setting NIX_PATH

```bash
# Add a custom path
export NIX_PATH="mypkgs=/home/user/my-nixpkgs:$NIX_PATH"

# Now use it
nix-instantiate --eval -E '<mypkgs>'
```

## The -I Flag

Override `NIX_PATH` for a single command:

```bash
nix develop -I /path/to/local-packages

nix eval --file -I /path/to/local myfile.nix
```

Paths from `-I` take precedence over `NIX_PATH`.

## Path Resolution

Nix searches paths from left to right:

```bash
NIX_PATH="first=/path1:second=/path2"

<Echo>    -> /path1/echo
<second/x> -> /path2/x
```

## Named Path Specifications

Use `name=path` syntax for explicit mappings:

```bash
NIX_PATH="nixpkgs=github:NixOS/nixpkgs/nixos-unstable"

nix develop
# Inside: import <nixpkgs> uses the flake URL
```

## Flake URLs in NIX_PATH

Modern Nix supports flake URLs directly:

```bash
NIX_PATH="nixpkgs=flake:nixpkgs"

nix eval --expr '<nixpkgs>'
```

This references the `nixpkgs` input from the flake registry.

## The Flake Registry

Nix maintains a registry of named flake references:

```bash
# List registered flakes
nix registry list

# Add a flake
nix registry add nixpkgs github:NixOS/nixpkgs/nixos-unstable

# Remove a flake
nix registry remove nixpkgs
```

After registration, `<nixpkgs>` automatically uses the flake.

## Local Flake References

Reference local flakes with `path:` URLs:

```bash
NIX_PATH="myflake=path:/home/user/myproject"

nix develop <myflake>
```

## Differences from nix-env

The `nix-env` command uses `~/.config/nix/exprs` instead of `NIX_PATH`:

```bash
# Where nix-env searches for packages
ls ~/.config/nix/exprs/
```

This is separate from `NIX_PATH` and is used by `nix-env -qa`.

## Common Patterns

**Project-specific packages:**
```bash
export NIX_PATH="myproject=/home/user/myproject:${NIX_PATH}"
```

**Channel override:**
```bash
export NIX_PATH="nixpkgs=/nix/store/...-nixpkgs-unstable"
```

**Temporary testing:**
```bash
nix develop -I /path/to/test-packages
```

## Troubleshooting Path Issues

```bash
# Check current NIX_PATH
echo $NIX_PATH

# Debug path resolution
nix-instantiate -E '<nixpkgs>' --eval

# List available paths
nix-instantiate --eval -E 'builtins.attrNames (import <nixpkgs> {})' | head
```

## Summary

- `NIX_PATH` defines search paths for angle-bracket references
- Use `name=path` syntax for explicit mappings
- `-I` flag overrides paths for single commands
- Flake URLs work in modern NIX_PATH
- `nix registry` manages named flake references
- `nix-env` uses a separate expression path

## Next Capsule

In the next capsule, we'll dive into **nixpkgs parameters**—the function that creates the package set and its configuration options.

```nix
# Next: ./pages/16-nixpkgs-parameters.md
```
