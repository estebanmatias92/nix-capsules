# Nix Capsules 15: Nixpkgs Deep Dive

## Introduction

In the previous capsule, we covered package composition patterns. Now we'll dive deep into **nixpkgs**—the central package collection that provides thousands of packages and utilities for Nix.

Understanding nixpkgs parameters and customization is essential for creating your own packages and customizing the package set.

## What is Nixpkgs?

Nixpkgs is:

- A **collection** of over 80,000 Nix packages
- A **function** that creates a package set for a specific system
- **The default source** for most Nix packages

When you write:

```nix
pkgs = import <nixpkgs> { };
```

You're calling the nixpkgs function with default parameters.

## The nixpkgs Function

The nixpkgs repository is actually a function that returns an attribute set:

```nix
import <nixpkgs> {
  system = builtins.currentSystem;
  config = { };
  overlays = [ ];
}
```

### Parameters

| Parameter | Type | Default | Purpose |
| --------- | ---- | ------- | ------- |
| `system` | string | `builtins.currentSystem` | Target platform |
| `config` | attrset | `{}` | Package configuration |
| `overlays` | list | `[]` | Modifications to apply |

### System Parameter

Specify which platform's packages to use:

```nix
# Use default system (x86_64-linux on most Linux)
pkgs = import <nixpkgs> { };

# Explicit system
pkgs = import <nixpkgs> {
  system = "x86_64-linux";
};

# Cross-compile to aarch64-darwin
pkgs = import <nixpkgs> {
  system = "aarch64-darwin";
};

# Check your current system
nix-repl> builtins.currentSystem
"x86_64-linux"
```

### Available Systems

```nix
"x86_64-linux"
"aarch64-linux"
"x86_64-darwin"
"aarch64-darwin"
```

## The config Parameter

Pass configuration options that packages can read:

```nix
pkgs = import <nixpkgs> {
  config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "openssl-1.1.1k"
    ];
  };
};
```

### Common Config Options

| Option | Type | Purpose |
| ------ | ---- | ------- |
| `allowUnfree` | bool | Build packages with restrictive licenses |
| `allowBroken` | bool | Build packages marked as broken |
| `permittedInsecurePackages` | list | Allow specific insecure versions |
| `enableGitHubFeatureFlags` | bool | Enable GitHub-specific features |

### Checking Config

```nix
nix-repl> pkgs.config.allowUnfree
true
```

### User Configuration File

Nixpkgs reads `~/.config/nixpkgs/config.nix` automatically:

```nix
# ~/.config/nixpkgs/config.nix
{
  allowUnfree = true;
  allowBroken = false;
}
```

This applies to all nixpkgs imports unless overridden.

## Overlays

Overlays modify the package set before returning it. An overlay is a function:

```nix
final: prev: {
  # Changes to apply
}
```

Where:

- `prev`: Package set before this overlay
- `final`: Package set after all overlays (including this one)

### Basic Overlay

```nix
pkgs = import <nixpkgs> {
  overlays = [
    (final: prev: {
      # Add a new package
      mypackage = final.callPackage ./mypackage.nix { };

      # Modify an existing package
      hello = prev.hello.override {
        enableDebug = true;
      };
    })
  ];
};
```

### Using Overlays in Flakes

Flakes provide cleaner overlay support:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    my-overlay.url = "github:user/my-overlay";
  };

  outputs = { self, nixpkgs, my-overlay }: {
    packages.x86_64-linux = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ my-overlay ];
      };
    in {
      inherit (pkgs) mypackage;
    };
  };
}
```

### Overlays as Default Export

Nix overlays can export as `default`:

```nix
# In my-overlay/flake.nix
{
  outputs = { self }: {
    defaultOverlay = final: prev: {
      mypackage = ...;
    };
  };
}

# In your flake.nix
{
  inputs.my-overlay.url = "github:user/my-overlay";

  outputs = { self, nixpkgs, my-overlay }: {
    overlays.default = my-overlay.default;
  };
}
```

### Overlay Order

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

## The Fixed-Point Pattern

Nixpkgs uses a fixed-point (let-rec) pattern internally:

```nix
pkgs = self: {
  a = 1;
  b = self.a + 2;  # References self.a
}
```

Overlays work by providing a new function that gets the previous packages as input:

```nix
(final: prev: {
  # prev.hello exists
  myhello = prev.hello.override { ... };
})
```

## packageOverrides (Legacy)

Older nixpkgs used `packageOverrides`:

```nix
{ pkgs ? import <nixpkgs> { } }:

pkgs.extend (final: prev: {
  graphviz = prev.graphviz.override { withXorg = false; };
})
```

Modern nixpkgs prefers overlays, but `packageOverrides` still works.

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

## Modifying Packages

### Using override

Change package attributes:

```nix
pkgs.hello.override {
  enableDebug = true;
}
```

### Using overrideAttrs

Change build attributes:

```nix
pkgs.hello.overrideAttrs (oldAttrs: {
  NIX_CFLAGS_COMPILE = "-O3";
})
```

### Overriding Dependencies

```nix
# Use a custom openssl
pkgs.curl.override {
  openssl = myCustomOpenssl;
}
```

## Package Information

Packages have useful attributes:

```nix
pkgs.hello.meta.description    # "A program that prints a friendly greeting"
pkgs.hello.version             # "2.12.1"
pkgs.hello.src                 # The source derivation
pkgs.hello.outPath             # Store path when built
pkgs.hello.passthru            # Custom attributes passed through
```

### Meta Attributes

```nix
{
  meta = {
    description = "Short description";
    longDescription = "Longer description for UI";
    homepage = "https://example.com";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.jdoe ];
    platforms = lib.platforms.linux;
    broken = false;
  };
}
```

## Platform-Specific Packages

Some packages only exist on certain platforms:

```nix
# Only on Linux
pkgs.linuxPackages_latest.kernel

# Only on Darwin
pkgs.darwin.apple_sdk.frameworks
```

### Checking Platforms

```nix
pkgs.stdenv.isLinux
pkgs.stdenv.isDarwin
pkgs.stdenv.isx86_64
```

### Platform Filters

```nix
# Only build on Linux
lib.filter (v: v.meta.platforms or lib.platforms.all)[*] == lib.platforms.linux)
```

## Accessing Nixpkgs Lib

Nixpkgs includes a utility library:

```nix
pkgs.lib.attrNames pkgs          # List all attributes
pkgs.lib.map (x: x + 1) [1 2 3]  # Apply function
pkgs.lib.concatMap ...           # Map and concatenate
pkgs.lib.flatten [ [1] [2 3] ]   # Flatten lists
```

### Common lib Functions

| Function | Purpose |
| -------- | ------- |
| `lib.attrNames` | List attribute names |
| `lib.map` | Apply function to list |
| `lib.filter` | Filter list |
| `lib.optional` | Conditionally include element |
| `lib.optionals` | Multiple optional elements |
| `lib.genAttrs` | Generate attributes |
| `lib.recursiveUpdate` | Deep merge attrsets |

## Using Different nixpkgs Versions

### Stable Channel

```nix
inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
```

### Unstable

```nix
inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
```

### Specific Commit

```nix
inputs.nixpkgs.url = "github:NixOS/nixpkgs?rev=abc123def456...";
```

## Troubleshooting

### Package Not Found

```nix
# Check if package exists
nix-instantiate -E '(import <nixpkgs> {}).hello' --eval

# List available packages
nix-env -qaP nixpkgs | grep hello
```

### Wrong Platform

```bash
# Error: attribute 'hello' missing
# Check current system
nix-instantiate -E 'builtins.currentSystem'
```

### Config Not Applied

```nix
# Config must be passed to import
pkgs = import <nixpkgs> {
  config.allowUnfree = true;  # Not from file
};
```

## Summary

- nixpkgs is a function accepting `system`, `config`, and `overlays`
- `system` selects the target platform
- `config` provides package configuration options
- Overlays modify the package set before use
- Use `override` and `overrideAttrs` for package changes
- Overlays are applied in order—later ones win
- User config at `~/.config/nixpkgs/config.nix` applies everywhere
- Packages have meta attributes for metadata

## Next Capsule

In the next capsule, we'll explore **advanced override patterns**—how to use `makeOverridable`, chain overrides, and understand the fixed-point pattern.

> [**Nix Capsules 16: Advanced Overrides**](./16-advanced-overrides.md)
