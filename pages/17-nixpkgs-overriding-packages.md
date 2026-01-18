# Nix Capsules 17: Nixpkgs Overriding Packages

## Introduction

Welcome to the seventeenth Nix capsule. In the previous capsule, we explored nixpkgs parameters. Now we'll see how to **override packages in nixpkgs**—modifying the package set so that all packages use your custom versions.

This is essential when you need system-wide changes, like using a patched version of a library.

## The packageOverrides Config

Nixpkgs supports a `packageOverrides` configuration that modifies the package set:

```nix
{ pkgs ? import <nixpkgs> { } }:

pkgs.extend (final: prev: {
  # Override graphviz to build without X support
  graphviz = prev.graphviz.override { withXorg = false; };

  # Add a custom package
  mypackage = prev.callPackage ./mypackage.nix { };
})
```

The `extend` method applies an overlay to the package set.

## Using Overrides with Config

Pass overrides through the config parameter:

```nix
{ config ? import ./config.nix }:

import <nixpkgs> {
  config = config;
}
```

**config.nix:**
```nix
{
  packageOverrides = pkgs: {
    graphviz = pkgs.graphviz.override { withXorg = false; };
  };
}
```

Nixpkgs automatically applies `packageOverrides` to the package set.

## The Fixed-Point Pattern

Nixpkgs uses a **fixed-point** (let-rec) pattern internally:

```nix
pkgs = self: {
  a = 1;
  b = self.a + 2;
}
```

This allows packages to reference each other. Overlays work by providing a new function that gets the previous packages as input.

## Applying Overrides to Dependent Packages

When you override a package, dependents automatically use the new version:

```nix
pkgs = import <nixpkgs> {
  config.packageOverrides = pkgs: {
    # Override glibc
    glibc = pkgs.glibc.override { ... };

    # All packages using glibc now use the overridden version
  };
};
```

This is the power of Nix—dependency changes propagate automatically.

## Overriding Multiple Packages

Override several packages at once:

```nix
{
  packageOverrides = pkgs: with pkgs; {
    # Security updates
    openssl = openssl_3_0;
    curl = curl.override { openssl = openssl_3_0; };

    # Custom builds
    python39 = python39.override {
      enableOptimizations = true;
    };
  };
}
```

## Per-User Overrides

Create user-specific overrides in `~/.config/nixpkgs/config.nix`:

```nix
{
  packageOverrides = pkgs: {
    # Use unstable versions for specific packages
    neovim = pkgs.neovim.unstable;
  };
}
```

## Overlay Priority

Overlays are applied in order—later overlays override earlier ones:

```nix
pkgs = import <nixpkgs> {
  overlays = [
    (final: prev: { foo = 1; })
    (final: prev: { foo = 2; })  # This wins
  ];
};

pkgs.foo  # Returns 2
```

Use `self: super` ordering to understand priority.

## Overriding in Development

For development, use flake overlays:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    my-patches.url = "github:user/my-patches";
  };

  outputs = { self, nixpkgs, my-patches }: {
    overlays.default = my-patches.overlays.default;
  };
}
```

Then reference with `nixpkgs overlays`.

## Troubleshooting Overrides

Debug override issues with:

```bash
# Show which package provides something
nix why-depends nixpkgs#final-package nixpkgs#base-package

# List all references
nix path-info --json /nix/store/...-package | jq -r '.[].references[]'

# Check derivation for override
nix derivation show /nix/store/...-package.drv
```

## Avoiding Infinite Recursion

Be careful with self-referential overrides:

```nix
# This can cause infinite recursion
pkgs = pkgs.extend (final: prev: {
  mypackage = prev.mypackage.override { deps = [ prev.mypackage ]; };
});
```

## Summary

- `packageOverrides` in config modifies the package set
- Use `pkgs.extend` to apply overlays directly
- Overridden dependencies propagate to dependents
- User config at `~/.config/nixpkgs/config.nix` applies everywhere
- Overlays are applied in order—later ones win

## Next Capsule

In the next capsule, we'll explore **Nix store paths**—how Nix computes the paths where build outputs are stored.

```nix
# Next: ./pages/18-nix-store-paths.md
```
