# Nix Capsules 8: Generic Builders

## Introduction

Welcome to the eighth Nix capsule. In the previous capsule, we built a simple C program with a custom builder script. Writing a new builder for each package is tedious. In this capsule, we'll create a **generic builder** that works for many projects, particularly those using autotools.

## The Autotools Build Pattern

Most GNU projects follow a standard build pattern:

```bash
./configure --prefix=$out
make
make install
```

We can create one generic builder that handles this pattern for any project following it.

## A Generic builder.sh

Create `builder.sh`:

```sh
#!/usr/bin/env bash
set -e

# Setup PATH with dependencies
export PATH="$coreutils/bin:$gcc/bin:$make/bin:$tar/bin:$gzip/bin:$ PATH"

# Unpack source
tar -xf "$src"

# Enter source directory (assume single directory)
cd *

# Configure
./configure --prefix="$out"

# Build
make

# Install
make install
```

This handles any autotools project with the right dependencies.

## Generic Builder Dependencies

The builder needs these tools in PATH:
- `tar` for unpacking archives
- `gcc` or `clang` for compilation
- `make` for running builds
- `coreutils` for basic utilities

## A Flake-based Approach

Instead of a custom builder script, use nixpkgs' `stdenv` with overrideable phases:

```nix
{
  description = "Generic builder example";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
  };
}
```

But for a custom project, use `mkDerivation` with custom phases:

```nix
let
  pkgs = import <nixpkgs> { };

in
pkgs.stdenv.mkDerivation {
  name = "hello-2.12.1";

  src = ./hello-2.12.1.tar.gz;

  buildPhase = ''
    echo "Building with custom logic..."
    gcc -o hello $src
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp hello $out/bin/hello
  '';
}
```

## Overriding buildPhase and installPhase

Nixpkgs' `stdenv` provides default phases. Override them as needed:

```nix
pkgs.stdenv.mkDerivation {
  name = "mypackage";

  src = ./source.tar.gz;

  preConfigure = ''
    # Run commands before configure
    ./bootstrap.sh
  '';

  configureFlags = [
    "--enable-feature-x"
    "--prefix=$out"
  ];

  buildPhase = ''
    # Custom build commands
    make -j$NIX_BUILD_CORES
  '';

  installPhase = ''
    make install
  '';
}
```

## Using makeWrapper for PATH Manipulation

For projects that need dependencies in PATH, use `makeWrapper`:

```nix
pkgs.stdenv.mkDerivation {
  name = "myapp";

  src = ./myapp.tar.gz;

  buildInputs = [ pkgs.someLibrary ];

  postInstall = ''
    wrapProgram $out/bin/myapp \
      --prefix PATH : "${pkgs.someLibrary}/bin"
  '';
}
```

## Generic Builder with buildInputs

The `buildInputs` attribute is a list of packages the built program needs at runtime:

```nix
pkgs.stdenv.mkDerivation {
  name = "graphviz";

  src = ./graphviz.tar.gz;

  buildInputs = [
    pkgs.gd
    pkgs.libpng
    pkgs.pkg-config
  ];

  configureFlags = [
    "--with-gd=${pkgs.gd}"
    "--with-libpng=${pkgs.libpng}"
  ];
}
```

`stdenv` automatically adds `buildInputs/bin` to PATH during configure and build phases.

## The phases Overview

`stdenv.mkDerivation` executes these phases by default:

1. **unpackPhase**: Extracts source archives
2. **patchPhase**: Applies patches
3. **configurePhase**: Runs `./configure` with appropriate flags
4. **buildPhase**: Runs `make`
5. **checkPhase**: Runs `make check` (can be disabled)
6. **installPhase**: Runs `make install`
7. **fixupPhase**: Strips binaries, patches shebangs

Each phase can be overridden or extended with `pre<Phase>` and `post<Phase>` hooks.

## Example: Extending a Phase

```nix
pkgs.stdenv.mkDerivation {
  name = "mypackage";

  src = ./mypackage.tar.gz;

  # Run custom code after installation
  postInstall = ''
    # Create additional files
    echo "Installed to $out" > $out/install.log
    chmod +x $out/bin/*
  '';
}
```

## Summary

- Generic builders avoid repeating common patterns
- `stdenv.mkDerivation` provides standard build phases
- Override phases with `pre<Phase>`, `post<Phase>`, and full overrides
- `buildInputs` adds dependencies to the PATH automatically
- Use `wrapProgram` for runtime PATH manipulation

## Next Capsule

In the next capsule, we'll explore how Nix automatically determines **runtime dependencies**—the libraries and files your built program actually needs to run.

```nix
# Next: ./pages/09-automatic-runtime-dependencies.md
```
