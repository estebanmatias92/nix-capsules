# Nix Capsules 13: Package Composition

## Introduction

In Capsule 12, we built a Flake with a single package defined inline. But real software is complex. You will likely have multiple files: a backend, a frontend, a library, and a main application that ties them together.

**Package Composition** is the art of wiring these dependencies together efficiently.

## The "Import" Trap (Fail-First)

When moving code to a separate file, your instinct might be to do this:

**File:** `my-package.nix` (BAD PATTERN)

```nix
# ⚠️ Do not do this!
let
  # VIOLATION: This ignores your flake.lock and fetches a new nixpkgs!
  # It creates a "Franken-build" where dependencies don't match your system.
  pkgs = import <nixpkgs> {};
in
pkgs.stdenv.mkDerivation {
  name = "my-package";
  # ...
}
```

**Why is this bad?**

1. **Impure:** It downloads a new version of `nixpkgs`, ignoring the one pinned in your `flake.lock`.
2. **Untestable:** You cannot swap `pkgs.gcc` for a different version if you want to test compatibility.

## Step 1: The Function Pattern (The Solution)

To fix this, we follow a simple rule: **Every Nix file should be a Function.**
It should not _import_ dependencies; it should _ask_ for them as arguments.

Create this file in your project directory:

**File:** `my-package.nix` (GOOD PATTERN)

```nix
{ stdenv, lib }:

stdenv.mkDerivation {
  name = "my-composed-package";

  # Hands-On Tip: We use dontUnpack so we don't need a source file for this demo.
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out
    echo "I was composed successfully!" > $out/success.txt
  '';
}
```

Now this file is "pure." It doesn't know where `stdenv` comes from; it just waits to receive it.

## Step 2: Manual Wiring (The Pain)

Now we need to call this function in our `flake.nix`.

**File:** `flake.nix`

```nix
{
  description = "Manual Composition Demo";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    # 1. Import the function
    packageFunc = import ./my-package.nix;
  in {
    packages.${system}.default =
      # 2. PAIN: We must manually pass every single argument.
      # If we add 'gcc' to my-package.nix later, this line breaks.
      packageFunc {
        stdenv = pkgs.stdenv;
        lib = pkgs.lib;
      };
  };
}
```

**Try it:**
Run `nix build`. It works, but imagine doing this for a package with 20 dependencies. It violates the **DRY** (Don't Repeat Yourself) principle.

## Step 3: The Mechanism (Glass Box)

How can we automate this? Nix has a superpower called **Reflection**. It can inspect its own functions to see what arguments they require.

Before using the "magic" tool, let's see how it works under the hood using the REPL.

```bash
nix repl
```

```nix
# Define a function with one mandatory arg (a) and one optional arg (b)
nix-repl> myFunc = { a, b ? 10 }: a + b

# Ask Nix: "What arguments does myFunc need?"
nix-repl> builtins.functionArgs myFunc
{ a = false; b = true; }
```

- `false` means: "Mandatory argument" (has no default value).
- `true` means: "Optional argument" (has a default value `?`).

This built-in function is the secret sauce. A helper script can look at `my-package.nix`, see it needs `stdenv`, look in `pkgs` for an attribute named `stdenv`, and pass it automatically.

## Step 4: Automation (`callPackage`)

Nixpkgs provides that helper script. It is called `callPackage`.

**Refactor your `flake.nix`:**

```nix
{
  description = "Automatic Composition Demo";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system}.default =
      # MAGIC SOLVED: callPackage uses 'functionArgs' to inspect './my-package.nix'
      # and fills the arguments from 'pkgs' automatically.
      pkgs.callPackage ./my-package.nix { };
  };
}
```

**Try it:**
Run `nix build`. It still works, but the code is much cleaner.

### Overriding Defaults

What if `my-package.nix` asks for `python`, but you need a specific version? You can explicitly override the auto-discovery in the second argument of `callPackage`:

```nix
pkgs.callPackage ./my-package.nix {
  # "Ignore what is in pkgs, use this instead"
  python = pkgs.python2;
}
```

## Step 5: Composition (Chaining Packages)

Real projects have chains of dependencies: `Frontend` depends on `Backend`. Since `Backend` is your own local package (not in nixpkgs), `callPackage` won't find it automatically. You must inject it.

Let's create two dummy packages to demonstrate this chain.

**File:** `backend.nix`

```nix
{ stdenv }:
stdenv.mkDerivation {
  name = "backend";
  dontUnpack = true;
  installPhase = "mkdir -p $out/bin; echo 'backend-binary' > $out/bin/server";
}
```

**File:** `frontend.nix`

```nix
{ stdenv, backend }:
stdenv.mkDerivation {
  name = "frontend";
  dontUnpack = true;
  buildInputs = [ backend ];
  installPhase = "mkdir -p $out; ln -s ${backend}/bin/server $out/server-link";
}
```

**File:** `flake.nix` (Final Version)

```nix
{
  description = "Chained Composition";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system} = rec {
      # 1. Build the backend (Standard)
      backend = pkgs.callPackage ./backend.nix { };

      # 2. Build the frontend (Custom Injection)
      # callPackage won't find 'backend' in pkgs, so we pass it manually.
      frontend = pkgs.callPackage ./frontend.nix {
        backend = backend;
      };

      default = frontend;
    };
  };
}
```

**Try it:**
Run `nix build`.
Check the result: `ls -l result/server-link`. It points to the backend store path!

## Summary

- **The Trap:** `import <nixpkgs>` inside files creates impurity. Avoid it.
- **The Fix:** Make every file a function (`{ inputs... }: ...`).
- **The Mechanism:** Nix uses `builtins.functionArgs` to reflect on your code and find dependency names.
- **The Tool:** `callPackage` uses that reflection to auto-wire dependencies.
- **Composition:** Use `callPackage` to wire your own local packages together.

## Next Capsule

We are creating packages, but we are also leaving a mess. Every build creates new store paths. How do we clean up the old ones?

> **[Nix Capsules 14: The Garbage Collector](./14-garbage-collector.md)**
