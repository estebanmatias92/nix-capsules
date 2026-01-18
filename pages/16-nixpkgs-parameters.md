# Nix Capsules 16: Nixpkgs Parameters

## Introduction

Welcome to the sixteenth Nix capsule. In the previous capsule, we explored search paths. Now we'll dive into **nixpkgs parameters**—the function that creates the package set and its configuration options.

The `nixpkgs` repository is a function that returns an attribute set of packages. Understanding its parameters lets you customize the entire package set.

## The nixpkgs Function

When you write:

```nix
pkgs = import <nixpkgs> { };
```

You're calling the nixpkgs function with an attribute set. The default parameters are:

```nix
import <nixpkgs> {
  system = builtins.currentSystem;
  config = {};
  overlays = [];
}
```

## The system Parameter

Specify which platform's packages to use:

```nix
# Use x86_64-linux (default on most systems)
pkgs = import <nixpkgs> { };

# Explicitly specify system
pkgs = import <nixpkgs> {
  system = "x86_64-linux";
};

# Cross-compile to aarch64-darwin
pkgs = import <nixpkgs> {
  system = "aarch64-darwin";
};
```

This selects the appropriate packages for that platform.

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

Common config options:
- **allowUnfree**: Build packages with restrictive licenses
- **permittedInsecurePackages**: Allow specific insecure versions
- **enableGitHubFeatureFlags**: Enable GitHub-specific features
- **pulseaudio**: Whether to build with PulseAudio support

## User Configuration File

Nixpkgs reads `~/.config/nixpkgs/config.nix` automatically:

```nix
# ~/.config/nixpkgs/config.nix
{
  allowUnfree = true;
  allowBroken = true;
}
```

This applies to all nixpkgs imports that don't override `config`.

## Overlays

Overlays modify the package set before returning it:

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

An overlay is a function: `(final: prev: { ... })`
- `prev`: The package set before this overlay
- `final`: The package set after all overlays
- Return modified attributes

## Using Overlays in Flakes

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

## Package Sets in Flakes

Flakes use `legacyPackages` for the package set:

```nix
let
  pkgs = nixpkgs.legacyPackages.x86_64-linux;
in
pkgs.hello
```

The system is determined by the flake output key.

## Accessing Package Information

Packages have useful attributes:

```nix
pkgs.hello.meta.description    # "A program that prints a friendly greeting"
pkgs.hello.version             # "2.12.1"
pkgs.hello.src                 # The source derivation
pkgs.hello.outPath             # Store path when built
```

## Platform-Specific Packages

Some packages only exist on certain platforms:

```nix
# Only on Linux
pkgs.linuxPackages_latest.kernel

# Only on Darwin
pkgs.darwin.apple_sdk.frameworks
```

Check platform compatibility with:

```nix
pkgs.stdenv.isLinux
pkgs.stdenv.isDarwin
```

## Configuring gcc and clang

Control which compilers are used:

```nix
pkgs = import <nixpkgs> {
  config = {
    allowUnfree = true;
    gcc = {
      enableMultilib = true;
    };
  };
};
```

## Summary

- nixpkgs is a function accepting `system`, `config`, and `overlays`
- `system` selects the target platform
- `config` provides package configuration options
- Overlays modify the package set before use
- Flakes use `legacyPackages` with system-specific keys

## Next Capsule

In the next capsule, we'll explore **overriding packages in nixpkgs**—using configuration and overlays to customize packages system-wide.

```nix
# Next: ./pages/17-nixpkgs-overriding-packages.md
```
