# Nix Capsules 13: Package Composition

## Introduction

In Capsule 12, we built a Flake with a single package defined inline. But real software is complex. You will likely have multiple files: a C library here, a Python script there, and a main application that ties them together.

**Package Composition** is the art of wiring these dependencies together efficiently.

## The "Import" Trap (What NOT to do)

When beginners split their code into multiple files, they often do this:

**File:** `my-package.nix` (BAD PATTERN)

```nix
# ⚠️ Do not do this!
let
  # Violates the Flake Lockfile!
  pkgs = import <nixpkgs> {};
in
pkgs.stdenv.mkDerivation {
  name = "my-package";
  buildInputs = [ pkgs.gcc ];
  # ...
}
```

**Why is this bad?**

1. **Breaks Purity:** This file imports `nixpkgs` directly, ignoring the locked version in your `flake.lock`.
2. **Hard to Test:** You cannot easily swap `pkgs.gcc` for a different compiler version to test compatibility.

## Step 1: The Inputs Pattern (The Solution)

To fix this, we follow a simple rule: **Every Nix file should be a Function.**

Instead of _importing_ dependencies, the file should _ask_ for them as arguments.

**File:** `my-package.nix` (GOOD PATTERN)

```nix
# We declare exactly what we need
{ stdenv, fetchurl, lib, gcc }:

stdenv.mkDerivation {
  name = "my-package";
  # ... use stdenv, gcc, etc.
}
```

Now this file is "pure." It doesn't know where `gcc` comes from; it just waits to receive it.

## Step 2: Manual Wiring (The Pain)

Now we need to call this function in our `flake.nix`.

```nix
outputs = { self, nixpkgs }: {
  packages.x86_64-linux.default = let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;

    # Import the function
    packageFunc = import ./my-package.nix;
  in
    # MANUALLY pass every single argument
    packageFunc {
      stdenv = pkgs.stdenv;
      fetchurl = pkgs.fetchurl;
      lib = pkgs.lib;
      gcc = pkgs.gcc;
    };
};
```

This works, but it is tedious. If you add `cowsay` to `my-package.nix`, you have to update the arguments in `flake.nix` too. This repetition violates the DRY (Don't Repeat Yourself) principle.

## Step 3: Automation (`callPackage`)

Nix provides a magic function called `callPackage`.

It looks at your function arguments (e.g., `{ stdenv, gcc }`), searches for attributes with the **same name** in `pkgs`, and passes them automatically.

**File:** `flake.nix` (Refactored)

```nix
outputs = { self, nixpkgs }: {
  packages.x86_64-linux.default = let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in
    # MAGIC:
    pkgs.callPackage ./my-package.nix { };
};
```

That's it. `callPackage` did the wiring for you.

### How does it know?

`callPackage` uses runtime reflection (`builtins.functionArgs`) to read the header of `my-package.nix`.

- It sees you need `gcc`.
- It looks inside `pkgs`.
- It finds `pkgs.gcc`.
- It injects it.

## Step 4: Overriding Defaults

Sometimes `pkgs` has the wrong version of a dependency. `callPackage` accepts a second argument: an **Override Set**.

Suppose `my-package.nix` needs `python`, but `pkgs.python` defaults to Python 3. You need Python 2 (for legacy reasons).

```nix
pkgs.callPackage ./my-package.nix {
  # Explicitly override the 'python' argument
  python = pkgs.python2;
}
```

Any argument you provide here takes precedence over the auto-discovery.

## Custom Composition (Chaining)

What if you have **two** local packages, and one depends on the other?

**File:** `backend.nix`

```nix
{ stdenv }: stdenv.mkDerivation { name = "backend"; ... }
```

**File:** `frontend.nix`

```nix
# This needs the backend!
{ stdenv, backend }: stdenv.mkDerivation { ... }
```

**File:** `flake.nix`

```nix
packages.x86_64-linux = let
  pkgs = nixpkgs.legacyPackages.x86_64-linux;
in rec {
  # 1. Build the backend
  backend = pkgs.callPackage ./backend.nix { };

  # 2. Build the frontend
  # Since 'backend' is not in standard nixpkgs, callPackage won't find it.
  # We must pass it manually.
  frontend = pkgs.callPackage ./frontend.nix {
    backend = backend;
    # Or simply: inherit backend;
  };
};
```

## Summary

- **The Problem:** Hardcoding imports breaks Flake purity.
- **The Pattern:** Make every file a function that takes arguments (`{ stdenv, dep1 }`).
- **The Tool:** Use `pkgs.callPackage ./file.nix {}` to automatically fill those arguments from the package set.
- **The Override:** Pass explicit arguments in the second set `{}` to override defaults or inject custom local packages.

## Next Capsule

We are creating packages, but we are also leaving a mess. Every build creates new store paths. How do we clean up the old ones?

> **[Nix Capsules 14: The Garbage Collector](./14-garbage-collector.md)**
