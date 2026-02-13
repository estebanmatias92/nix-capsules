# Nix Capsules 15: Nixpkgs Deep Dive

## Introduction

In the previous capsule, we learned how to clean up the store. Now we will look at the source of all our software: **Nixpkgs**.

So far, we have accessed packages using `nixpkgs.legacyPackages.x86_64-linux`. This is convenient, but it gives you the **default** version of every package.

What if you need to:

1. Install software with an "Unfree" license (like Slack, Discord, or Unrar)?
2. Apply a security patch to a system library?
3. Add your own custom package to the main set?

To do this, you must stop treating Nixpkgs as a static list and start treating it as a **Function**.

## The "Unfree" Trap (Fail-First)

Nix is strict about software licenses. By default, it refuses to build non-free software.

Let's try to build `unrar`, a common tool with a non-free license.

**File:** `flake.nix`

```nix
{
  description = "Unfree Trap";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: {
    # We try to use the default legacyPackages
    packages.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.unrar;
  };
}
```

**Try it:**
Run `nix build`.

**The Failure:**
You will see a large error message:
`error: Package ‘unrar-6.x.x’ in ... has an unfree license (‘unrar’), refusing to evaluate.`

**Why?**
You might be tempted to google "how to allow unfree nix" and find tutorials telling you to edit `~/.config/nixpkgs/config.nix`.
**Do not do this.** Flakes are **pure**. They ignore your user configuration files to ensure that if it builds on your machine, it builds on mine.

You must configure this _inside_ the Flake.

## Step 1: The Nixpkgs Function (Glass Box)

The input `nixpkgs` is not just a directory of files; it contains a function definition that builds the package set.

When you use `legacyPackages`, Nix calls this function with defaults. To change the defaults, we must call it manually using `import`.

The signature looks like this:

```nix
import nixpkgs {
  system = "x86_64-linux";  # Mandatory: Which architecture?
  config = { ... };         # Optional: Flags like allowUnfree
  overlays = [ ... ];       # Optional: Custom modifications
}
```

## Step 2: Configuring Nixpkgs

Let's fix our Flake by explicitly importing `nixpkgs` with the configuration we need.

**File:** `flake.nix` (Refactored)

```nix
{
  description = "Configured Nixpkgs";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";

    # We instantiate our own version of pkgs
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };
  in {
    # Now we use OUR 'pkgs', not the default 'legacyPackages'
    packages.${system}.default = pkgs.unrar;
  };
}
```

**Try it:**
Run `nix build`. It works!

## Step 3: Overlays (Modifying the Set)

Configuration flags are limited. What if you want to change the version of a package or inject a new one?

We use **Overlays**.
An overlay is a function that takes two arguments:

1. `final`: The final package set (after all modifications).
2. `prev`: The package set before this modification.

It returns a set of packages to **merge** into the main set.

### The Syntax

```nix
final: prev: {
  # We can add new packages
  my-script = prev.writeScriptBin "hi" "echo hi";

  # We can override existing ones
  hello = prev.hello.overrideAttrs (old: {
    # Changing the source or build steps
    doCheck = false;
  });
}
```

### Applying an Overlay

Let's modify our Flake to inject a custom package into `pkgs`.

**File:** `flake.nix`

```nix
{
  description = "Overlay Demo";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";

    # Define the overlay
    myOverlay = final: prev: {
      # Let's override 'hello' to disable its tests (doCheck)
      hello = prev.hello.overrideAttrs (old: {
        doCheck = false;
      });

      # Let's add a custom tool
      my-tool = prev.writeShellScriptBin "my-tool" ''
        echo "I am now part of pkgs!"
      '';
    };

    # Apply the overlay during import
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ myOverlay ];
    };

  in {
    packages.${system} = {
      default = pkgs.my-tool;
      customHello = pkgs.hello;
    };
  };
}
```

**Try it:**

1. `nix run .#default` -> Prints "I am now part of pkgs!"
2. `nix build .#customHello` -> Builds hello (skipping tests).

## Inspecting with REPL

You can use the REPL to inspect your configured `pkgs` set.

```bash
nix repl
```

```nix
# Load the flake
nix-repl> :lf .

# Check config
nix-repl> packages.x86_64-linux.default.src.url or "Custom Package"
"Custom Package"

nix-repl> packages.x86_64-linux.customHello.src.url or "Custom Package"
"mirror://gnu/hello/hello-2.12.2.tar.gz"
```

## Summary

- **Legacy vs Modern:** `legacyPackages` uses defaults. `import nixpkgs` allows customization.
- **Purity:** Global config (`~/.config/nixpkgs`) is ignored in Flakes. You must use `config.allowUnfree = true` inside the flake.
- **The Function:** `import nixpkgs { system, config, overlays }`.
- **Overlays:** The standard way to inject or modify packages (`final: prev: { ... }`).

## Next Capsule

In the next capsule, we will take overrides to the next level. We will learn how to change a package's inputs (e.g., compile `git` with a different version of `openssl`) using `.override`.

> **[Nix Capsules 16: Advanced Overrides](./16-advanced-overrides.md)**
