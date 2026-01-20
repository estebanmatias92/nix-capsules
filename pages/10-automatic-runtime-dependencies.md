# Nix Capsules 9: Automatic Runtime Dependencies

## Introduction

Welcome to the ninth Nix capsule. In the previous capsule, we used generic builders to package software. But how does Nix know what a built program needs at **runtime**? In this capsule, we'll explore Nix's automatic runtime dependency detection—a powerful feature that ensures programs have all their libraries available.

## Build vs Runtime Dependencies

**Build dependencies** are packages needed during compilation. You specify these explicitly with `buildInputs`.

**Runtime dependencies** are packages needed when the program runs. Nix discovers these **automatically** by analyzing the built output.

This is one of Nix's most powerful features: you only specify build-time dependencies, and Nix figures out runtime needs.

## How Nix Discovers Runtime Dependencies

Nix analyzes the built output (the NAR archive) and scans for references to other store paths:

```bash
nix path-info --json /nix/store/...-hello | jq -r '.[].references[]'
```

This shows all store paths the output references. For a typical program, you'll see:

- `glibc` - The C library
- `gcc-libs` - GCC runtime libraries
- Other shared libraries the program links against

## Viewing Runtime Dependencies

Build a simple program and check its runtime dependencies:

```nix
# hello.nix using stdenv
{ nixpkgs ? import <nixpkgs> { } }:

nixpkgs.stdenv.mkDerivation {
  name = "hello";
  src = ./hello.c;
  buildPhase = ''
    gcc -o hello $src
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp hello $out/bin/hello
  '';
}
```

```bash
nix build .
nix path-info --json ./result | jq -r '.[].references[]'
```

The output shows dependencies like:

```bash
/nix/store/...-glibc-2.38
/nix/store/...-gcc-13.2.0-lib
```

## The RPATH Issue

When linking dynamically, the compiler embeds an RPATH—a list of directories where libraries should be found at runtime:

```bash
patchelf --print-rpath ./result/bin/hello
```

In traditional systems, RPATH points to `/usr/lib`. In Nix, it should point to the specific library paths in the store.

Nix automatically handles this through:

1. **patchelf**: Rewrites RPATH to use store paths
2. **stdenv**: Automatically runs patchelf on ELF binaries

## Shrinking RPATH

For minimal RPATHs (only including actually-used paths), use `patchelf --shrink-rpath`:

```bash
patchelf --shrink-rpath ./result/bin/hello
```

This removes RPATH entries that aren't actually needed.

## Stripping Binaries

Remove debugging symbols to reduce file size:

```bash
strip ./result/bin/hello
```

`stdenv` does this automatically in the `fixupPhase`.

## Automatic Dependency Collection

Nix scans built executables for:

- Shared library references (`.so` files)
- Script shebangs pointing to store paths
- Hardcoded paths to other store locations

This scan happens during realization, and the results are stored in the derivation's metadata.

## Verifying Runtime Closure

Check that your package's runtime closure is complete:

```bash
# List all paths in the closure (JSON format)
nix path-info --json --recursive ./result | jq -r 'keys[]'

# Or show sizes for each path
nix path-info --json --recursive --size ./result | jq '.'
```

A complete closure includes the main program plus all dependencies, plus their dependencies, recursively.

## Example: Graphviz Runtime Dependencies

Graphviz depends on libraries for various formats:

```nix
{ nixpkgs ? import <nixpkgs> { } }:

nixpkgs.stdenv.mkDerivation {
  name = "graphviz";
  src = ./graphviz.tar.gz;

  buildInputs = with nixpkgs; [
    gd
    libpng
    libjpeg
    fontconfig
    pkg-config
  ];
}
```

After building, check its runtime dependencies:

```bash
nix path-info --json $(readlink -f result) | jq -r '.[].references[]'
```

You'll see `gd`, `libpng`, `fontconfig`, and their transitive dependencies—all automatically discovered.

## Runtime Dependency Best Practices

1. **Don't hardcode paths**: Use `$out` and let Nix handle paths
2. **Use stdenv**: It handles RPATH and stripping automatically
3. **Minimize dependencies**: Only add buildInputs you truly need
4. **Test on clean systems**: Use `nix copy` to test closure completeness

## Summary

- Nix automatically discovers runtime dependencies by scanning built outputs
- References to store paths are traced through the NAR archive
- RPATH handling ensures binaries find their libraries
- Use `nix path-info --json <path> | jq -r '.[].references[]'` to inspect runtime dependencies
- Stdenv handles patching and stripping automatically

## Next Capsule

In the next capsule, we'll use `nix develop` to create isolated development environments—perfect for hacking on projects without polluting your system.

> [**Nix Capsules 11: Developing with nix develop**](./11-developing-with-nix-shell.md)
