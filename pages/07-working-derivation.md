# Nix Capsules 7: Working Derivation

## Introduction

Welcome to the seventh Nix capsule. In the previous capsule, we created a derivation but didn't build anything useful. Now we'll write a **working derivation** that compiles a simple C program and produces a real binary.

The key is using a builder script that creates the `$out` path.

## A Simple Builder Script

Create `builder.sh` in your project directory:

```sh
#!/usr/bin/env bash
set -e

echo "Building..."

# Create the output directory
mkdir -p "$out"

# Compile a simple C program
gcc -o "$out/hello" "$src"

echo "Build complete!"
```

This script:
1. Exits on any error (`set -e`)
2. Creates the output directory at `$out`
3. Compiles `src` (passed as a derivation attribute) to `$out/hello`

## The Derivation

Create `hello.nix`:

```nix
let
  nixpkgs = import <nixpkgs> { };
in
derivation {
  name = "hello";
  builder = "${nixpkgs.bash}/bin/bash";
  args = [ ./builder.sh ];
  src = ./hello.c;
  system = builtins.currentSystem;
  gcc = nixpkgs.gcc;
  coreutils = nixpkgs.coreutils;
}
```

Key points:
- Builder is Bash from nixpkgs
- `args` passes the builder script to bash
- `src` is the C source file (will be stored in the Nix store)
- `gcc` and `coreutils` are dependencies—their paths become available to the builder

## Creating hello.c

```c
#include <stdio.h>

int main() {
    printf("Hello from Nix!\n");
    return 0;
}
```

## Building with nix build

Use the modern `nix build` command:

```bash
# Build and create a result symlink
nix build .

# Or specify the package explicitly
nix build .#hello
```

The result symlink points to the built output:

```bash
./result/bin/hello
# Output: Hello from Nix!
```

## How the Builder Receives Dependencies

Every attribute in the derivation becomes an environment variable. Derivations convert to their output paths:

```bash
# In the builder, these environment variables are set:
gcc = /nix/store/...-gcc-12.2.0/bin/gcc
coreutils = /nix/store/...-coreutils-9.1/bin
src = /nix/store/...-hello.c
out = /nix/store/...-hello
```

The builder's `PATH` isn't set automatically—you set it yourself or use nixpkgs' stdenv (covered later).

## Improving the Builder

Add PATH setup for convenience:

```sh
#!/usr/bin/env bash
set -e

export PATH="${coreutils}/bin:${gcc}/bin:$PATH"

mkdir -p "$out"
gcc -o "$out/hello" "$src"
```

Now `gcc` and basic utilities (`mkdir`, etc.) are available.

## Using a Flake for Simplicity

Create `flake.nix`:

```nix
{
  description = "Hello program";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.hello = let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in
      pkgs.stdenv.mkDerivation {
        name = "hello";
        src = ./hello.c;
        buildPhase = ''
          gcc -o hello $src
        '';
        installPhase = ''
          mkdir -p $out/bin
          cp hello $out/bin/hello
        '';
      };
  };
}
```

Build with `nix build .#hello`.

## Understanding Derivation Attributes

The derived attributes tell Nix how to build:

```nix
derivation {
  name = "hello";           # Output name
  system = "x86_64-linux";  # Target platform
  builder = "...";          # Build script interpreter
  args = [ ... ];           # Arguments to builder
  src = ./hello.c;          # Source files
  gcc = ...;                # Build dependencies
}
```

The `.drv` file records these for later building.

## Debugging Builds

Use `nix develop` to enter a shell with the build environment:

```bash
nix develop .#hello
```

Then manually run build steps to debug. Use `nix log` to see build logs:

```bash
nix log /nix/store/...-hello
```

## Summary

- Builders must create files at `$out`
- Derivation attributes become environment variables
- Use `nix build` to build derivations
- Flakes provide a cleaner project structure
- `nix develop` helps debug build issues

## Next Capsule

In the next capsule, we'll generalize our builder for any autotools-based project, avoiding custom scripts for each package.

```nix
# Next: ./pages/08-generic-builders.md
```
