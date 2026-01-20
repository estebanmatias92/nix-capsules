# Nix Capsules 13: Package Composition

## Introduction

In the previous capsule, we explored flake architecture. Now we'll learn **package composition**—how to organize multiple packages and their dependencies efficiently.

As your project grows beyond one package, you need a way to compose them. The inputs pattern and callPackage provide flexible, modular approaches.

## The Single Repository Pattern

Nix follows a **single repository** pattern: all package definitions live in one place (like nixpkgs). This enables:

- Consistent dependency resolution across packages
- Easy overriding of any package
- Shared tooling and conventions

```nix
# A simple repository structure
{
  hello = import ./hello.nix;
  graphviz = import ./graphviz.nix;
}
```

## The Inputs Design Pattern

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

## Passing Inputs to Packages

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
    inherit mkDerivation gd libpng pkg-config;
    gd = nixpkgs.gd;
    libpng = nixpkgs.libpng;
    pkg-config = nixpkgs.pkg-config;
  };
}
```

This decouples package definitions from the repository structure.

## Benefits of Input Passing

1. **Testability**: Easy to substitute mock dependencies
2. **Customization**: Pass different versions without modifying packages
3. **Reusability**: Use packages in different contexts
4. **Clarity**: Dependencies are explicit and visible

## The callPackage Design Pattern

With the inputs pattern, we repeat parameter names. `callPackage` eliminates this duplication:

```nix
let
  pkgs = import <nixpkgs> { };

  callPackage = path: args:
    let
      f = import path;
      params = builtins.functionArgs f;
      autoArgs = builtins.intersectAttrs params pkgs;
    in
      f (autoArgs // args);
in
{
  graphviz = callPackage ./graphviz.nix { };
}
```

Now `callPackage` automatically passes `mkDerivation`, `gd`, etc. from `pkgs`.

## Built-in callPackage

Nixpkgs provides `callPackage` as part of its standard library:

```nix
pkgs.callPackage ./graphviz.nix { }
```

## Overriding Arguments

Pass overrides as the second argument:

```nix
graphviz = pkgs.callPackage ./graphviz.nix {
  gd = customGd;
};
```

The override takes precedence over auto-passed values.

## Default Arguments

Provide defaults in the package definition:

```nix
{ mkDerivation, gdSupport ? true, gd ? null }:

mkDerivation {
  name = "graphviz";
  src = ./graphviz.tar.gz;

  buildInputs = lib.optionals gdSupport (lib.optionals (gd != null) [ gd ]);
}
```

## Understanding functionArgs

Inspect what parameters a function expects:

```nix
nix-repl> f = { a, b ? 2 }: a + b
nix-repl> builtins.functionArgs f
{ a = true; b = false; }
```

## Using intersectAttrs

`callPackage` uses `intersectAttrs` to match parameters:

```nix
nix-repl> params = { a = true; b = true; c = true; }
nix-repl> pkgs = { a = 1; b = 2; d = 4; }
nix-repl> builtins.intersectAttrs params pkgs
{ a = 1; b = 2; }
```

Only matching attributes are passed.

## Flake-based callPackage

With flakes, use `callPackage` from the outputs:

```nix
outputs = { self, nixpkgs }: let
  pkgs = nixpkgs.legacyPackages.x86_64-linux;
  callPackage = path: pkgs.lib.callPackageWith pkgs path;
in {
  packages.default = callPackage ./hello.nix { };
};
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

## The with Expression

Reduce repetition with `with`:

```nix
let pkgs = import <nixpkgs> { };
in with pkgs;
{
  hello = stdenv.mkDerivation { ... };
  graphviz = stdenv.mkDerivation { ... };
}
```

## Best Practices

1. **Explicit inputs**: List all dependencies as function parameters
2. **Avoid imports in packages**: Pass everything from the repository
3. **Use defaults**: Provide sensible defaults for optional inputs
4. **Use callPackage**: Reduces boilerplate while maintaining explicitness

## Summary

- The inputs pattern makes packages functions that receive dependencies
- `callPackage` automatically passes matching arguments
- Repository expressions compose packages with their inputs
- Use defaults for optional parameters

## Next Capsule

In the next capsule, we'll explore **garbage collection**—how to clean up unused store paths and manage disk space in Nix.

```nix
# Next: ./pages/14-garbage-collector.md
```
