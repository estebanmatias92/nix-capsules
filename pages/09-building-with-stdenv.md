# Nix Capsules 9: Building with stdenv

## Introduction

In the previous capsule, we explored store path mechanics. Now we'll explore **stdenv**—the **standard environment** that provides build utilities and phases for most Nix packages.

`stdenv` is a set of conventions and tools that makes packaging software consistent across thousands of packages in nixpkgs.

## What is stdenv?

`stdenv` is a Nix derivation that provides:

- A shell environment for builds
- Standard build phases (unpack, configure, build, install)
- Common build tools (make, gcc, shell)
- Automatic RPATH handling and binary patching

Most packages use `stdenv.mkDerivation` instead of the raw `derivation` builtin.

## Using stdenv.mkDerivation

```nix
{ stdenv }:

stdenv.mkDerivation {
  name = "hello-2.12.1";
  src = ./hello-2.12.1.tar.gz;
}
```

That's it! No builder script needed—stdenv handles everything.

## Build Phases

`stdenv` executes these phases in order:

1. **unpackPhase**: Extracts source archives
2. **patchPhase**: Applies patches from `patches` attribute
3. **configurePhase**: Runs `./configure` with flags
4. **buildPhase**: Runs `make`
5. **checkPhase**: Runs `make check` (can be disabled)
6. **installPhase**: Runs `make install`
7. **fixupPhase**: Strips binaries, patches RPATH

## Unpack Phase

Automatically handles:

- `.tar.gz`, `.tar.bz2`, `.tar.xz`, `.zip`, etc.
- Single directory extraction
- Sets `$src` to unpacked directory

Override with:

```nix
unpackPhase = ''
  tar -xf $src
  cd my-custom-dir
'';
```

## Configure Phase

Runs `./configure` with:

- `--prefix=$out` for installation destination
- `--build` and `--host` from `$stdenv`
- Additional flags from `configureFlags`

```nix
configureFlags = [
  "--enable-feature-x"
  "--without-docs"
];
```

## Build Phase

Runs `make` with:

- `$makeFlags` if specified
- Parallelization from `$NIX_BUILD_CORES`

```nix
makeFlags = [ "V=1" ];  # Verbose build
```

## Check Phase

Runs tests by default. Disable for unreliable tests:

```nix
doCheck = false;
```

Or customize:

```nix
checkPhase = ''
  make test-unit
'';
```

## Install Phase

Runs `make install`. Customize with:

```nix
installPhase = ''
  make install PREFIX=$out
  mkdir -p $out/share/doc
  cp README $out/share/doc/
'';
```

## Fixup Phase

Automatically:

- Strips binaries (`strip`)
- Patches RPATH with `patchelf`
- Patches shebangs in scripts

Disable with:

```nix
dontPatchShebangs = true;
dontStrip = true;
```

## The stdenv Setup Script

`stdenv` provides a `setup` script that all phases source:

```bash
source $stdenv/setup
```

This sets:

- `PATH` with build tools
- Environment variables (`$out`, `$src`, `$CC`, etc.)
- Helper functions (`configure`, `build`, `install`)

## Environment Variables

`stdenv` sets these automatically:

```bash
$out          # Final installation directory
$src          # Unpacked source directory
$stdenv       # stdenv derivation path
$system       # Target system (e.g., x86_64-linux)
$CC           # C compiler
$CXX          # C++ compiler
$LD           # Linker
$NIX_BUILD_CORES  # Parallel jobs
```

## Customizing Phases

Use `pre<Phase>` and `post<Phase>` hooks:

```nix
preBuild = ''
  echo "About to build..."
  # Run custom setup
'';

postInstall = ''
  # Post-install tasks
  chmod +x $out/bin/*
'';
```

## Complete Example

```nix
{ stdenv, lib, fetchurl }:

stdenv.mkDerivation {
  name = "graphviz-2.50.0";

  src = fetchurl {
    url = "https://example.com/graphviz-2.50.0.tar.gz";
    sha256 = "sha256-abc123...";
  };

  buildInputs = [ stdenv.gd stdenv.libpng stdenv.pkg-config ];

  configureFlags = [
    "--with-gd=${stdenv.gd}"
    "--with-libpng=${stdenv.libpng}"
  ];

  postInstall = ''
    # Graphviz needs special post-install
    ln -s $out/bin/dot $out/bin/dot-2.50
  '';
}
```

## Cross-Compilation Support

`stdenv` supports cross-compilation through additional attributes:

```nix
stdenv.mkDerivation {
  name = "mypackage";
  dontConfigure = true;

  preConfigure = ''
    export CC=${stdenv.cc}/bin/${stdenv.stdenv.hostPlatform.config}-gcc
  '';
}
```

## Summary

- `stdenv` provides standard build phases and utilities
- `stdenv.mkDerivation` is the preferred way to create packages
- Phases can be customized with hooks or full overrides
- Environment variables like `$out` are automatically set
- Cross-compilation is supported through platform attributes
- The `setup` script is sourced to initialize the build environment

## Next Capsule

In the next capsule, we'll explore **runtime dependencies**—how Nix automatically discovers what libraries and files your built program needs to run.

```nix
# Next: ./10-automatic-runtime-dependencies.md
```
