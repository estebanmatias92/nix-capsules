# Nix Capsules 14: Override Design Pattern

## Introduction

Welcome to the fourteenth Nix capsule. In the previous capsule, we used `callPackage` to simplify package composition. Now we'll explore the **override design pattern**—a way to customize packages by modifying their attributes after creation, enabling composition of transformations.

## The Override Concept

Sometimes you want to create a package variant without rewriting the entire definition. The override pattern adds an `override` method to the package that lets you change input attributes.

**Without override:**
```nix
# Must reimport with different inputs
graphvizNoX = import ./graphviz.nix {
  inherit mkDerivation;
  gdSupport = false;
};
```

**With override:**
```nix
# Start from the existing package and override
graphvizNoX = graphviz.override { gdSupport = false; };
```

## Implementing makeOverridable

Nixpkgs provides `lib.makeOverridable` to add override capability:

```nix
lib.makeOverridable = f: origArgs:
  let
    res = f origArgs;
  in
    res // {
      override = newArgs:
        f (origArgs // newArgs);
    };
}
```

This wraps a function to return the result plus an `override` method.

## Usage Example

**make-overridable.nix:**
```nix
{ mkDerivation, gdSupport ? true, gd ? null }:

lib.makeOverridable (args:
  mkDerivation ({
    name = "graphviz";
    src = ./graphviz.tar.gz;

    buildInputs = lib.optionals gdSupport (
      lib.optionals (gd != null) [ gd ]
    );
  } // args)
) { inherit mkDerivation gd gdSupport; }
```

The outer `makeOverridable` call wraps the package definition.

## Chaining Overrides

Override multiple attributes sequentially:

```nix
let
  base = import ./graphviz.nix { inherit mkDerivation; };
  noGd = base.override { gdSupport = false; };
  customName = noGd.override { name = "graphviz-custom"; };
in
  customName
```

Each `override` call creates a new derivation with the merged arguments.

## Recursive Overrides

The result of `override` is also overridable:

```nix
let
  graphviz = import ./graphviz.nix { inherit mkDerivation; };
  variant = graphviz.override { gdSupport = false; }
                    .override { name = "my-graphviz"; };
in
  variant
```

## Overriding in a Repository

Use overrides when composing packages:

```nix
let
  pkgs = import <nixpkgs> { };
  callPackage = pkgs.lib.callPackageWith pkgs;

  graphviz = callPackage ./graphviz.nix { };

  # Override for a specific use case
  graphvizForCI = graphviz.override {
    doCheck = false;  # Skip tests in CI
  };
in
{
  inherit graphviz graphvizForCI;
}
```

## Override and buildInputs

Override can change dependencies:

```nix
# Use a custom version of gd
graphvizCustomGd = graphviz.override {
  gd = myCustomGd;
};
```

The entire dependency graph updates to use the new `gd`.

## Practical Use Cases

1. **Disable tests**: `.override { doCheck = false; }`
2. **Custom flags**: `.override { configureFlags = [...]; }`
3. **Patch versions**: `.override { version = "2.50"; src = ...; }`
4. **Runtime dependencies**: `.override { additionalLibs = [ extraLib ]; }`

## Override vs callPackage

| Aspect | callPackage | override |
|--------|-------------|----------|
| When used | Initial composition | Post-creation modification |
| Parameters | Function parameters | Derivation attributes |
| Flexibility | Explicit arguments | Any overridable attribute |
| Use case | Setting up dependencies | Tweaking existing package |

Both patterns are useful—use `callPackage` for initial composition, `override` for variants.

## Flake-based Overrides

With flakes, overrides work the same way on the returned packages:

```nix
{
  outputs = { self, nixpkgs }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in {
    packages.x86_64-linux = {
      graphviz = pkgs.graphviz;
      graphvizNoX = pkgs.graphviz.override { gdSupport = false; };
    };
  };
}
```

## Summary

- The override pattern adds a method to customize packages after creation
- `lib.makeOverridable` wraps functions to enable overriding
- Overrides can be chained for multiple modifications
- Works well with `callPackage` for flexible package management
- Enables creating variants without duplicating package definitions

## Next Capsule

In the next capsule, we'll explore **Nix search paths**—how Nix locates expressions like `<nixpkgs>` and how to configure them.

```nix
# Next: ./pages/15-nix-search-paths.md
```
