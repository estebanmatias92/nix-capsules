# Nix Capsules 12: Flake Architecture

## Introduction

In Capsule 11, we created a development shell. However, we did it somewhat "loosely." In this capsule, we formalize the **Contract** of your project using **Flakes**.

A Flake is not magic; it is simply a standard way to write a Nix function. It transforms **Inputs** (dependencies) into **Outputs** (packages, shells, apps).

## The Anatomy of a Flake

A `flake.nix` file is a Nix Attribute Set with two mandatory keys.

```nix
{
  # 1. INPUTS: "What do I need?"
  # Sources, libraries, and other flakes.
  inputs = { ... };

  # 2. OUTPUTS: "What do I produce?"
  # A function that takes the downloaded inputs and returns artifacts.
  outputs = { self, nixpkgs, ... }: { ... };
}
```

### 1. The Inputs (The Source of Truth)

Inputs are resources your project needs. While `github` is the default, Nix can fetch from almost anywhere.

```nix
inputs = {
  # 1. Standard GitHub (Flakes)
  nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  # 2. Local Paths (Crucial for development)
  # Allows you to depend on a library on your own disk.
  my-lib.url = "path:/home/user/projects/my-lib";

  # 3. Non-Flake Sources (The 'flake = false' trick)
  # Useful to fetch raw source code (like a C project) that doesn't have a flake.nix.
  zsh-src = {
    url = "github:zsh-users/zsh/master";
    flake = false;
  };
};
```

> **Pro Tip:** When you use `flake = false`, the input isn't treated as a Nix library. Instead, it is treated as a **directory path** to the source code, which you can then pass to a builder (like `stdenv.mkDerivation`).

### 2. The Outputs (The Schema)

This is where the structure becomes strict. Unlike a random `.nix` file where you can return anything, a Flake expects specific attributes targeted at specific architectures.

The schema follows this pattern:
`outputType.<system>.<name>`

Example:
`packages.x86_64-linux.default`

## Step 1: The Raw Flake (Glass Box)

Let's write a flake _without_ any helper libraries to understand the raw schema. We will define a **Package** (from Capsule 09) and a **Shell** (from Capsule 11).

**File:** `flake.nix`

```nix
{
  description = "My First Raw Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    # 1. PACKAGES: Artifacts we can build
    # Schema: packages.<system>.<name>
    packages.${system}.default = pkgs.hello;

    # 2. DEV SHELLS: Environments we can enter
    # Schema: devShells.<system>.<name>
    devShells.${system}.default = pkgs.mkShell {
      packages = [ pkgs.cowsay ];
      shellHook = ''
        echo "Welcome to the Flake!"
      '';
    };
  };
}
```

### Inspecting the Flake

Nix provides a command to view what a flake provides:

```bash
$ nix flake show

git+file:///...
├───devShells
│   └───x86_64-linux
│       └───default: development environment 'nix-shell'
└───packages
    └───x86_64-linux
        └───default: package 'hello-2.12.1'
```

## Step 2: The "Git Trap" (Fail-First)

Flakes enforce **Purity**. To see this in action, we need to be inside a git repository.

1. Initialize git and track **only** the flake file:

```bash
git init
git add flake.nix
```

_(Note: We are deliberately NOT adding other files yet)._ 2. Create a simple script and reference it:

```bash
echo "echo I am hidden" > hidden.sh

# Do not forget to make it executable
chmod +x hidden.sh
```

Add it to your `shellHook` in `flake.nix`:

```nix
shellHook = ''
  bash ./hidden.sh
'';
```

1. Run `nix develop`.

**The Failure:**
Now you will get an error saying the file does not exist (`No such file or directory`).

**The Reason:**
Since `hidden.sh` is not in the git staging area, Nix **cannot see it**. It copied only `flake.nix` to the store.

**The Fix:**
Add the file to git so Nix knows it is part of the project source.

```bash
git add hidden.sh
```

## The Lockfile (`flake.lock`)

Run `nix develop`. You will notice a new file appears: `flake.lock`.

Open it. You will see it has resolved `github:nixos/nixpkgs` to a specific Git commit hash (e.g., `rev: 5f3a...`).

- **Before Lock:** "Use the unstable branch." (Mutable, dangerous).
- **After Lock:** "Use exactly commit `5f3a...`." (Immutable, reproducible).

This file ensures that if you share this project with a friend 6 months from now, they will use the **exact same version** of GCC, Python, and Glibc that you used today.

## Step 3: Reducing Boilerplate (Automation)

In "Step 1", we hardcoded `system = "x86_64-linux"`. But what if we want this to work on a MacBook (`aarch64-darwin`) too?

We would have to copy-paste the code for every architecture. To avoid this, we use helper functions. You can use the popular library `flake-utils`, or write a simple helper function yourself.

Here is the standard "For All Systems" pattern:

```nix
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    # List of systems we support
    systems = [ "x86_64-linux" "aarch64-darwin" ];

    # A helper to run a function for each system
    forAllSystems = function:
      nixpkgs.lib.genAttrs systems (system:
        function nixpkgs.legacyPackages.${system}
      );
  in
  {
    # Now we just describe the logic once!
    packages = forAllSystems (pkgs: {
      default = pkgs.hello;
    });

    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = [ pkgs.go ];
      };
    });
  };
}
```

## Summary

- **Inputs:** Sources defined by URLs.
- **Outputs:** A function returning a strict schema (`type.system.name`).
- **Purity:** Nix only sees files tracked by Git.
- **Lockfile:** Pins inputs to exact commits for reproducibility.
- **Multi-Architecture:** We use helper functions (like `genAttrs` or `flake-utils`) to generate outputs for Linux and macOS simultaneously.

## Next Capsule

Now that we have the structure, we need to talk about **Package Composition**. How do we combine multiple packages? How do we pass one package as an input to another?

> **[Nix Capsules 13: Package Composition](./13-package-composition.md)**
