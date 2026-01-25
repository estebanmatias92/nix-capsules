# Nix Capsules 10: Automatic Runtime Dependencies

## Introduction

Welcome to the ninth Nix capsule. In the previous capsule, we used generic builders to package software. But how does Nix know what a built program needs at **runtime**? In this capsule, we'll explore Nix's automatic runtime dependency detection—a powerful feature that ensures programs have all their libraries available.

## Build vs Runtime Dependencies

**Build dependencies** are packages needed during compilation. You specify these explicitly with `buildInputs`.

**Runtime dependencies** are packages needed when the program runs. Nix discovers these **automatically** by analyzing the built output.

This is one of Nix's most powerful features: you only specify build-time dependencies, and Nix figures out runtime needs.

## How Nix Discovers Runtime Dependencies

Nix analyzes the built output (the NAR archive) and scans for references to other store paths:

```bash
nix-store -q --references /nix/store/...-hello
```

This shows all store paths the output references. For a typical program, you'll see:

- `glibc` - The C library
- `gcc-libs` - GCC runtime libraries
- Other shared libraries the program links against

## Viewing Runtime Dependencies

Build a simple program and check its runtime dependencies:

```nix
{
  description = "A simple flake to compile hello.c";

  # 1. Inputs: Define external dependencies (replaces 'import <nixpkgs>')
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  # 2. Outputs: A function that takes inputs and produces artifacts
  outputs = { self, nixpkgs }:
  let
    # Flakes do not guess the system architecture; it must be explicit.
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    # Standard schema: packages.<architecture>.<name>
    packages.${system}.default = pkgs.stdenv.mkDerivation {
      name = "hello";

      # CRITICAL: In Flakes, local files must be tracked by git.
      # You must run `git add hello.c` before building.
      src = ./.;

      # We use the GCC compiler provided by stdenv
      buildPhase = ''
        gcc -o hello hello.c
      '';

      installPhase = ''
        mkdir -p $out/bin
        cp hello $out/bin/hello
      '';
    };
  };
}
```

```bash
nix build .
nix-store -q --references ./result
```

The output shows dependencies like:

```bash
/nix/store/...-glibc-2.38
```

## The RPATH Issue

When linking dynamically, the compiler embeds an RPATH—a list of directories where libraries should be found at runtime:

```bash
# Use patchelf from ephimeral shell to inspect RPATH
nix shell nixpkgs#patchelf -c patchelf --print-rpath ./result/bin/hello
```

In traditional systems, RPATH points to `/usr/lib`. In Nix, it should point to the specific library paths in the store.

Nix automatically handles this through:

1. **patchelf**: Rewrites RPATH to use store paths
2. **stdenv**: Automatically runs patchelf on ELF binaries

## Shrinking RPATH

`stdenv` automatically attempts to shrink the `RPATH` to keep the closure small. It runs a command equivalent to:

```bash
# (Internal Step)
patchelf --shrink-rpath ...
```

## Stripping Binaries

To reduce file size, stdenv automatically strips debugging symbols during the fixupPhase. It runs:

```bash

# (Internal Step)
strip ...
```

`stdenv` does this automatically in the `fixupPhase`.

## Automatic Dependency Collection

Nix scans built executables for:

- Shared library references (`.so` files)
- Script shebangs pointing to store paths
- Hardcoded paths to other store locations

This scan happens during realization, and the results are stored in the derivation's metadata.

## Verifying Runtime Closure

A **Runtime Closure** is the complete list of everything your program needs to run on another machine. It includes the program itself, its direct dependencies, and _their_ dependencies (recursively).

To verify this, use `nix-store` queries that provide structural insight:

### 1. Visualize the Dependency Tree

To understand _why_ a package is included (e.g., transitive dependencies), visualize the hierarchy:

```bash
# Shows a visual ASCII tree of dependencies
$ nix-store -q --tree ./result

/nix/store/pmrqz67p7lvjm99y0bwkn1yyq1i73cn4-hello
└───/nix/store/j193mfi0f921y0kfs8vjc1znnr45ispv-glibc-2.40-66
    ├───/nix/store/6h39qxzrm4i1fhl538knvyjapcdyasfx-xgcc-15.2.0-libgcc
    ├───/nix/store/kywwgk85nl83mpf10av3bvm2khdlq5ib-libidn2-2.3.8
    │   ├───/nix/store/hlcdbvwjlzjd2x86fxghzj1gpzplccqw-libunistring-1.4.1
  ...
```

### 2. List All Requisites

To get a flat list of all store paths required (e.g., for copying or auditing):

```bash
# Lists every unique store path in the closure
$ nix-store -qR ./result

/nix/store/6h39qxzrm4i1fhl538knvyjapcdyasfx-xgcc-15.2.0-libgcc
/nix/store/hlcdbvwjlzjd2x86fxghzj1gpzplccqw-libunistring-1.4.1
/nix/store/kywwgk85nl83mpf10av3bvm2khdlq5ib-libidn2-2.3.8
/nix/store/j193mfi0f921y0kfs8vjc1znnr45ispv-glibc-2.40-66
/nix/store/pmrqz67p7lvjm99y0bwkn1yyq1i73cn4-hello
```

### 3. Check Total Size

To measure the real disk usage of the package plus all its dependencies (crucial for deployment planning):

```bash
# Calculate total size of the closure
$ du -hc $(nix-store -qR ./result) | tail -n1

33M     total
```

## Example: Graphviz Runtime Dependencies

Graphviz depends on libraries for various formats:

```nix
{
  description = "Nix Capsule Reference: Multi-package Flake";

  # 1. Inputs: Sources for dependencies (replaces channels)
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  # 2. Outputs: The function that produces the artifacts
  outputs = { self, nixpkgs }:
  let
    # Explicit system architecture definition
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    # 'packages' is a set. You can define multiple distinct packages here.
    packages.${system} = {

      # ==========================================
      # Package 1: The Default (Hello World)
      # Build with: nix build
      # ==========================================
      default = pkgs.stdenv.mkDerivation {
        name = "hello";

        # SOURCE NOTE: In Flakes, './.' only sees files tracked by git.
        # You MUST run `git add hello.c` or this will fail.
        src = ./.;

        # stdenv provides GCC and Make by default
        buildPhase = ''
          gcc -o hello hello.c
        '';

        installPhase = ''
          mkdir -p $out/bin
          cp hello $out/bin/hello
        '';
      };

      # ==========================================
      # Package 2: Graphviz Custom (Dependency Demo)
      # Build with: nix build .#graphviz-custom
      # ==========================================
      graphviz-custom = pkgs.stdenv.mkDerivation {
        name = "graphviz-custom";

        # We fetch source from the web. Nix verifies the content with a hash.
        src = pkgs.fetchurl {
          url = "https://gitlab.com/api/v4/projects/4207231/packages/generic/graphviz-releases/12.2.1/graphviz-12.2.1.tar.gz";
          # IMPORTANT: When you run this for the first time, it will fail.
          # Nix will calculate the real hash and show it to you.
          # Copy that hash and replace the zeros below.
          sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        };

        # BUILD INPUTS vs RUNTIME DEPENDENCIES
        # We list libraries here so they are available during compilation.
        # Nix automatically detects which ones are actually used by the binary
        # (via RPATH scanning) and keeps only those for the runtime closure.
        buildInputs = with pkgs; [
          gd          # For image support
          libpng
          libjpeg
          fontconfig
        ];

        # Tools needed strictly for building (not runtime)
        nativeBuildInputs = [ pkgs.pkg-config ];
      };

    };
  };
}
```

**Build the package**:

_Note: Since we used a placeholder hash (AAAA...), the first build will fail. This is normal! Nix protects you from unverified downloads._

1. Run the build to get the error:

```bash
nix build .#graphviz-custom
```

1. Copy the actual hash from the error message (look for got: sha256-...).

2. Update your flake.nix with the correct hash.
3. Run the build again.

**Check Runtime Dependencies**:

Once built successfully:

```bash
nix-store -q --tree ./result
```

You'll see `gd`, `libpng`, and their transitive dependencies—all automatically discovered.

## Runtime Dependency Best Practices

1. **Don't hardcode paths**: Use `$out` and let Nix handle paths
2. **Use stdenv**: It handles RPATH and stripping automatically
3. **Minimize dependencies**: Only add buildInputs you truly need
4. **Test on clean systems**: Use `nix copy` to test closure completeness

## Summary

- Nix automatically discovers runtime dependencies by scanning built outputs
- References to store paths are traced through the NAR archive
- RPATH handling ensures binaries find their libraries
- Use `nix-store -q --references <path>` to inspect runtime dependencies
- Stdenv handles patching and stripping automatically

## Next Capsule

In the next capsule, we'll use `nix develop` to create isolated development environments—perfect for hacking on projects without polluting your system.

> **[Nix Capsules 11: Developing with nix develop](./11-developing-with-nix-shell.md)**
