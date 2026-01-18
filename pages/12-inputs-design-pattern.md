# Nix Capsules 12: Inputs Design Pattern

## Introduction

Welcome to the twelfth Nix capsule. In the previous capsule, we cleaned up with the garbage collector. Now we'll organize multiple packages with the **inputs design pattern**—a foundational approach for managing software repositories in Nix.

As your project grows beyond one package, you need a way to compose them. The inputs pattern provides a flexible, modular approach.

## Single Repository Pattern

Nix follows a **single repository** pattern: all package definitions live in one place (like nixpkgs). This enables:

- Consistent dependency resolution across packages
- Easy overriding of any package
- Shared tooling and conventions

```nix
# A simple repository
{
  hello = import ./hello.nix;
  graphviz = import ./graphviz.nix;
}
```

## Passing Inputs to Packages

Each package should declare its dependencies as inputs, rather than importing nixpkgs directly:

**graphviz.nix:**
```nix
{ mkDerivation, gd, libpng, pkg-config }:

mkDerivation {
  name = "graphviz";
  src = ./graphviz.tar.gz;

  buildInputs = [
    gd
    libpng
    pkg-config
  ];
}
```

The package is a function that receives its dependencies as parameters.

## The Repository Expression

Combine packages in a top-level expression:

**default.nix:**
```nix
let
  nixpkgs = import <nixpkgs> { };
  mkDerivation = nixpkgs.stdenv.mkDerivation;
in
{
  hello = import ./hello.nix {
    inherit mkDerivation;
  };
  graphviz = import ./graphviz.nix {
    inherit mkDerivation;
    gd = nixpkgs.gd;
    libpng = nixpkgs.libpng;
    pkg-config = nixpkgs.pkg-config;
  };
}
```

This decouples package definitions from the repository structure.

## Flake-based Repository

With flakes, this becomes cleaner:

**flake.nix:**
```nix
{
  description = "My package repository";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.hello =
      let pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in pkgs.hello;

    packages.x86_64-linux.graphviz =
      let pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in pkgs.graphviz;
  };
}
```

## The Benefits of Input Passing

1. **Testability**: Easy to substitute mock dependencies
2. **Customization**: Pass different versions without modifying packages
3. **Reusability**: Use packages in different contexts
4. **Clarity**: Dependencies are explicit and visible

## Overriding Inputs

Create variants by passing different inputs:

```nix
{
  # Standard graphviz
  graphviz = import ./graphviz.nix { ... };

  # Graphviz without X support
  graphviz-no-x = import ./graphviz.nix {
    inherit mkDerivation;
    gd = nixpkgs.gd;
    # No libx11, libxt, etc.
  };
}
```

## Conditional Inputs

Use Nix's conditionals to make features optional:

```nix
{ mkDerivation, gdSupport ? true, gd }:

mkDerivation {
  name = "graphviz";
  src = ./graphviz.tar.gz;

  buildInputs = [
    (lib.optional gdSupport gd)
  ];
}
```

With `lib.optional`:
- If `gdSupport` is true: `[gd]`
- If false: `[]`

## Input Set Patterns

Use attribute sets for related inputs:

```nix
{ mkDerivation, libs ? { gd = null; libpng = null; } }:

mkDerivation {
  name = "graphviz";
  src = ./graphviz.tar.gz;

  buildInputs = lib.filterAttrs (k: v: v != null) libs;
}
```

This allows passing a subset of libraries.

## The with Expression

Reduce repetition with `with`:

```nix
let
  pkgs = import <nixpkgs> { };
in
with pkgs;
{
  hello = stdenv.mkDerivation { ... };
  graphviz = stdenv.mkDerivation { ... };
}
```

`with pkgs;` brings all pkgs attributes into scope for the following expression.

## Best Practices

1. **Explicit inputs**: List all dependencies as function parameters
2. **Avoid imports in packages**: Pass everything from the repository
3. **Use defaults**: Provide sensible defaults for optional inputs
4. **Document inputs**: Comment on non-obvious dependencies

## Summary

- The inputs pattern makes packages functions that receive dependencies
- Repository expressions compose packages with their inputs
- Flakes provide a standardized project structure
- Conditional inputs enable feature toggles
- The `with` expression reduces repetition

## Next Capsule

In the next capsule, we'll simplify repository composition with the **callPackage design pattern**—automatic argument passing for package functions.

```nix
# Next: ./pages/13-callpackage-design-pattern.md
```
