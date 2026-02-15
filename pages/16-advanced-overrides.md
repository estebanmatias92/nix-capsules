# Nix Capsules 16: Advanced Overrides

## Introduction

In the previous capsules, we learned how to use `callPackage` to wire dependencies together and how to configure `nixpkgs`.

But what happens when a package in `nixpkgs` (or your own local package) is _almost_ perfect, but you need to change one small detail? You don't want to copy-paste the entire source code into a new file just to change a URL or a build flag.

Nix solves this with **Overrides**.

## The `.override` Trap (Fail-First)

When beginners discover overrides, they often try to do this:

```nix
# ⚠️ This will fail!
my-custom-hello = pkgs.hello.override {
  name = "hello-custom-version";
  doCheck = false;
};

```

**The Failure:**
If you run this, Nix will throw an error:
`error: function 'anonymous lambda' called with unexpected argument 'name'`

**Why is this bad?**
You are confusing the **Nix Function** with the **Derivation**.

- `name` and `doCheck` are attributes of `stdenv.mkDerivation`.
- `.override` does **not** change derivation attributes; it changes the arguments passed to the Nix function at the top of the file (e.g., `{ stdenv, fetchurl, ... }:`).

To master overrides, you must understand the difference between `.override` and `.overrideAttrs`.

## Step 1: The Base Package (Our Target)

Let's create a functional, self-contained package to experiment on. It takes a custom argument (`enableGreeting`) to toggle its behavior.

**File:** `my-app.nix`

```nix
# THE FUNCTION HEADER (Modified by .override)
{ stdenv, enableGreeting ? true }:

# THE DERIVATION (Modified by .overrideAttrs)
stdenv.mkDerivation {
  name = "my-app";
  dontUnpack = true;

  # We use the function argument to change the build logic
  greeting = if enableGreeting then "Hello, Nix!" else "...Silence...";

  installPhase = ''
    mkdir -p $out/bin
    echo "echo '$greeting'" > $out/bin/my-app
    chmod +x $out/bin/my-app
  '';
}

```

## Step 2: Using `.override` (Function Arguments)

If we want to change `enableGreeting` to `false`, we use `.override`.

When you use `pkgs.callPackage ./my-app.nix {}`, Nix automatically attaches a special `.override` method to the resulting package.

### Complete Example

**File:** `flake.nix`

```nix
{
  description = "Override Demo";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system}.default = (pkgs.callPackage ./my-app.nix { }).override {
        enableGreeting = false;
      };
    };
}

```

**Try it:**

```bash
nix run
# Output: ...Silence...

```

> **Didactic Check:** Can I use `.override` to change `stdenv`?
> Yes! Because `stdenv` is listed in the function header `{ stdenv, enableGreeting ? true }:`, you could pass a different compiler (e.g., `.override { stdenv = pkgs.clangStdenv; }`).

## Step 3: Using `.overrideAttrs` (Derivation Attributes)

What if we want to change the `name` of the package or add a new phase, but the function header doesn't have an argument for it?

We use `.overrideAttrs`. This method takes a function that receives the `old` attributes and returns the new ones.

### Complete Example

**File:** `flake.nix`

```nix
{
  description = "overrideAttrs Demo";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system}.default = (pkgs.callPackage ./my-app.nix { }).overrideAttrs (old: {
        name = "${old.name}-customized";

        # We append to the existing installPhase
        postInstall = ''
          echo "echo 'Extra Line'" >> $out/bin/my-app
        '';
      });
    };
}

```

**Try it:**

```bash
nix run
# Output: Hello, Nix!
#         Extra Line

```

## Step 4: The Mechanism (Glass Box)

How does a package magically get these `.override` methods? It is not a feature of the Nix language; it is a feature of the `nixpkgs` library.

Let's inspect our package attributes using `nix eval`:

```bash
nix eval --json .#default.override 2>/dev/null | head -c 200
# Shows the override function is present

```

Or inspect the derivation directly:

```bash
nix derivation show .#default | grep -A5 '"override"'
# Shows the override mechanism in the derivation

```

1. **`overrideAttrs`**: This is attached natively by `stdenv.mkDerivation`. Every standard package has it.
2. **`override`**: This is attached by `callPackage` using a wrapper called `lib.makeOverridable`.

If you were to write the `makeOverridable` logic yourself, it looks like this:

```nix
# How callPackage makes your function overridable (Simplified)
lib.makeOverridable = func: originalArgs:
  let
    result = func originalArgs;
  in
    result // {
      override = newArgs: func (originalArgs // newArgs);
    };

```

It simply saves your original arguments, and when you call `.override`, it merges the new arguments and calls the function again!

## Step 5: Chaining Overrides

You can chain multiple `.override` and `.overrideAttrs` calls to create exactly the variant you need.

**File:** `flake.nix`

```nix
{
  description = "Chained Overrides Demo";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # 1. The Base Package
      base-app = pkgs.callPackage ./my-app.nix { };

    in {
      packages.${system} = {
        # The default outputs "Hello, Nix!"
        default = base-app;

        # 2. Chaining Overrides
        # First we silence it, then we rename it.
        custom = base-app.override {
          enableGreeting = false;
        }.overrideAttrs (old: {
          name = "my-app-silent";
        });
      };
    };
}

```

**Try it out:**

```bash
# Run the default:
nix run .#default
# Output: Hello, Nix!

# Run the overridden version:
nix run .#custom
# Output: ...Silence...

```

## Summary

- **`.override`**: Modifies the **Function Arguments** (the inputs at the top of your `.nix` file). Attached by `callPackage` via `lib.makeOverridable`.
- **`.overrideAttrs`**: Modifies the **Derivation Attributes** (the parameters passed to `stdenv.mkDerivation` like `name`, `src`, `installPhase`).
- **Chaining**: You can safely chain multiple `.override` and `.overrideAttrs` calls to create exactly the variant you need without touching the original source code.

## Next Capsule

In the next capsule, we'll explore **dependency propagation**—how packages pass dependencies to their dependents automatically through attributes like `propagatedBuildInputs` and setup hooks.

> **[Nix Capsules 17: Dependency Propagation](./17-dependency-propagation.md)**
