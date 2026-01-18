# Nix Capsules 13: callPackage Design Pattern

## Introduction

Welcome to the thirteenth Nix capsule. In the previous capsule, we used the inputs pattern to compose packages. But specifying inputs twice (once in the package, once in the repository) is tedious. In this capsule, we'll use **callPackage** to automatically pass arguments to package functions.

## The Problem callPackage Solves

With the inputs pattern, we write:

```nix
# In the repository
graphviz = import ./graphviz.nix {
  inherit mkDerivation gd libpng pkg-config;
};

# In graphviz.nix
{ mkDerivation, gd, libpng, pkg-config }: ...
```

We repeat the parameter names. `callPackage` eliminates this duplication.

## How callPackage Works

`callPackage` is a function that:
1. Imports a Nix file (which returns a function)
2. Inspects the function's parameters
3. Automatically passes matching attributes from a set

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
let
  pkgs = import <nixpkgs> { };
in
{
  graphviz = pkgs.callPackage ./graphviz.nix { };
}
```

Or use the `lib` helper:

```nix
lib.callPackageWith pkgs ./graphviz.nix { }
```

## Overriding Arguments

Pass overrides as the second argument:

```nix
# Use custom gd instead of pkgs.gd
graphviz = pkgs.callPackage ./graphviz.nix {
  gd = customGd;
};
```

The override takes precedence over auto-passed values.

## Complete Repository Example

**default.nix:**
```nix
let
  nixpkgs = import <nixpkgs> { };

  callPackage = nixpkgs.lib.callPackageWith nixpkgs;

in
rec {
  hello = callPackage ./hello.nix { };

  graphviz = callPackage ./graphviz.nix {
    # Optional overrides
  };

  myGraphviz = callPackage ./graphviz.nix {
    gdSupport = false;
  };
}
```

**graphviz.nix:**
```nix
{ mkDerivation, gdSupport ? true, gd, libpng, pkg-config }:

mkDerivation {
  name = "graphviz";
  src = ./graphviz.tar.gz;

  buildInputs = lib.optionals gdSupport [ gd libpng ]
    ++ [ pkg-config ];
}
```

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

Now `callPackage` can omit `gd` if `gdSupport` is false.

## Understanding functionArgs

Inspect what parameters a function expects:

```nix
nix-repl> f = { a, b ? 2 }: a + b
nix-repl> builtins.functionArgs f
{ a = true; b = false; }
```

The result shows:
- `a = true`: Required parameter
- `b = false`: Optional parameter (has default)

## Using intersectAttrs

`callPackage` uses `intersectAttrs` to match parameters:

```nix
nix-repl> params = { a = true; b = true; c = true; }
nix-repl> pkgs = { a = 1; b = 2; d = 4; }
nix-repl> builtins.intersectAttrs params pkgs
{ a = 1; b = 2; }
```

Only matching attributes are passed—this is the key to automatic argument passing.

## Flake-based callPackage

With flakes, use `callPackage` from the outputs:

```nix
{
  description = "My repository";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    callPackage = path: pkgs.lib.callPackageWith pkgs path;
  in {
    packages.x86_64-linux = rec {
      hello = callPackage ./hello.nix { };
      graphviz = callPackage ./graphviz.nix { };
    };
  };
}
```

## Benefits of callPackage

1. **Less repetition**: Don't list parameters twice
2. **Explicit overrides**: Clear when arguments are customized
3. **Composable**: Easy to create package variants
4. **Discoverable**: See available parameters from the package file

## Summary

- `callPackage` automatically passes arguments to package functions
- Uses `functionArgs` to inspect parameters and `intersectAttrs` to match them
- Overrides are passed as the second argument
- Reduces boilerplate while maintaining explicitness
- Works with both traditional expressions and flakes

## Next Capsule

In the next capsule, we'll explore the **override design pattern**—another way to customize packages by modifying their attributes after creation.

```nix
# Next: ./pages/14-override-design-pattern.md
```
