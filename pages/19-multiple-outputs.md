# Nix Capsules 19: Multiple Outputs

## Introduction

In the previous capsule, we explored store internals. Now we'll learn about **multiple outputs**—a powerful feature that lets you split a single derivation into multiple store paths.

Multiple outputs are essential for:
- Reducing closure sizes (install only what you need)
- Organizing packages (binaries, docs, dev files separate)
- Optimizing deployment (only deploy runtime files)

## Why Multiple Outputs?

Consider a package like GTK:

```
gtk/
├── bin/           # Runtime binaries
├── lib/           # Libraries (runtime)
├── include/       # Headers (development only)
├── share/         # Data files
└── lib/pkgconfig/ # .pc files (development only)
```

If you only need the runtime library, you shouldn't need headers and pkgconfig files. Multiple outputs solve this.

## Basic Syntax

Define multiple outputs with the `outputs` attribute:

```nix
stdenv.mkDerivation {
  name = "mypackage-1.0";

  outputs = ["out" "doc" "dev"];

  installPhase = ''
    mkdir -p $out $doc $dev

    # Runtime to out
    cp bin/* $out/bin/
    cp lib/*.so $out/lib/

    # Documentation to doc
    cp -r man $doc/
    cp README $doc/

    # Development files to dev
    cp -r include $dev/
    cp lib/*.pc $dev/lib/pkgconfig/
  '';
}
```

### Output Names

| Name | Convention | Contents |
|------|------------|----------|
| `out` | Always present | Main package |
| `bin` | Optional | Executables (added to PATH) |
| `lib` | Optional | Libraries |
| `dev` | Optional | Headers, pkg-config files |
| `doc` | Optional | Documentation |
| `man` | Optional | Manual pages |
| `info` | Optional | Info documentation |

## Environment Variables

Each output gets its own environment variable:

```bash
$out           # Path to "out" output
$doc           # Path to "doc" output
$dev           # Path to "dev" output

$outBin        # $out/bin (convenience)
$outLib        # $out/lib (convenience)
```

### Default Output

The `out` output is the default—accessing `pkgs.hello` is the same as `pkgs.hello.out`.

## Automatic PATH Addition

The `bin` output is special—its `bin` directory is automatically added to PATH:

```nix
stdenv.mkDerivation {
  name = "mypackage";

  outputs = ["out" "bin"];

  installPhase = ''
    mkdir -p $out $bin
    cp mybinary $bin/
    cp data $out/
  '';
}
```

Using `$bin` means executables are in PATH.

## Using Multiple Outputs in Nixpkgs

Nixpkgs uses multiple outputs extensively:

```nix
nix-repl> pkgs.hello.outputs
[ "out" ]

nix-repl> pkgsgtk3.outputs
[ "out" "bin" "dev" "doc" "lib" "man" ]
```

### Referencing Specific Outputs

```nix
# Runtime only
pkgs.gtk3.out

# Development files
pkgs.gtk3.dev

# Binaries
pkgs.gtk3.bin

# Documentation
pkgs.gtk3.doc
```

### Default vs Specific

```nix
# Default output
pkgs.gtk3       # Same as pkgs.gtk3.out

# Specific output
pkgs.gtk3.dev   # Development files only
```

## Constructing Outputs Efficiently

### Using makeScope

Nixpkgs provides helpers for multiple outputs:

```nix
{ lib, stdenv, fetchurl }:

stdenv.mkDerivation (finalAttrs: {
  name = "hello-2.12.1";

  src = fetchurl {
    url = "mirror://gnu/hello/hello-2.12.1.tar.gz";
    sha256 = "abc123...";
  };

  outputs = [ "out" "doc" ];

  makeFlags = [ "DESTDIR=$(doc)" ];

  postInstall = ''
    moveToOutput "share/info" "$doc"
  '';
})
```

### Using moveToOutput

The `moveToOutput` helper moves files from `$out` to another output:

```nix
postInstall = ''
  moveToOutput "share/man" "$doc"
  moveToOutput "share/info" "$doc"
  moveToOutput "include" "$dev"
'';
```

## Setting Permissions

Different outputs may need different permissions:

```nix
stdenv.mkDerivation {
  name = "mypackage";

  outputs = ["out" "dev"];

  installPhase = ''
    mkdir -p $out $dev

    # Main package - world-readable
    cp data $out/
    chmod 644 $out/*

    # Development files - same
    cp headers $dev/
    chmod 644 $dev/*
  '';
}
```

## Separable Packages

Some packages mark outputs as separable:

```nix
stdenv.mkDerivation {
  name = "libfoo";

  outputs = ["out" "dev"];

  dontBuildDev = true;  # Don't build dev output
  dontInstallDev = true;  # Don't install dev files
}
```

This skips unnecessary work when you only need the runtime.

## Build Inputs with Multiple Outputs

When using packages with multiple outputs:

```nix
stdenv.mkDerivation {
  name = "myapp";

  buildInputs = [ pkgs.gtk3 ];

  # By default, all outputs are available
  # Configure looks in $dev for headers
  # Runtime links against $out/lib
}
```

### Specifying Which Outputs

By default, all outputs are included. You can specify:

```nix
buildInputs = [
  # Only runtime from gtk3
  pkgs.gtk3.out
  # Only development from libfoo
  pkgs.libfoo.dev
];
```

## Benefits of Multiple Outputs

### 1. Smaller Closures

Only install what you need:

```bash
# Install only runtime
nix profile install nixpkgs#gtk3.out

# Install with development files
nix profile install nixpkgs#gtk3.dev
```

### 2. Faster Deployments

Deploy only runtime files to production:

```nix
# Deploy script
nix copy --to ssh://server /nix/store/*-gtk3-out
```

### 3. Cleaner Systems

Keep development files separate from runtime:

```bash
# Production server - only out
/nix/store/*-gtk3-out/

# Development machine - all outputs
/nix/store/*-gtk3-out/
/nix/store/*-gtk3-dev/
/nix/store/*-gtk3-doc/
```

## Common Patterns

### Pattern 1: Library with Development Files

```nix
stdenv.mkDerivation {
  name = "mylib-1.0";

  outputs = ["out" "dev"];

  buildInputs = [ pkgs.pkg-config ];

  configureFlags = [
    "--prefix=$out"
    "--includedir=$dev/include"
    "--libdir=$out/lib"
    "--pkgconfigdir=$dev/lib/pkgconfig"
  ];

  postInstall = ''
    moveToOutput "include" "$dev"
    moveToOutput "lib/pkgconfig" "$dev/lib/pkgconfig"
  '';
}
```

### Pattern 2: Application with Documentation

```nix
stdenv.mkDerivation {
  name = "myapp-1.0";

  outputs = ["out" "doc"];

  installPhase = ''
    mkdir -p $out $doc
    cp myapp $out/bin/
    cp -r man $doc/
    cp README.md $doc/
  '';
}
```

### Pattern 3: Tools with Plugins

```nix
stdenv.mkDerivation {
  name = "editor-1.0";

  outputs = ["out" "plugins"];

  installPhase = ''
    mkdir -p $out $plugins
    cp editor $out/bin/
    cp -r plugins/* $plugins/
  '';
}
```

## Querying Multiple Outputs

```bash
# Show all outputs for a package
nix eval nixpkgs#gtk3.outputs

# Build specific output
nix build .#gtk3.dev

# Show what an output contains
nix store ls /nix/store/*-gtk3-dev/

# Check references
nix path-info /nix/store/*-gtk3-out
```

## Best Practices

1. **Use conventional names**: `out`, `bin`, `dev`, `doc`, `man`
2. **Separate runtime from development**: Users can install only what they need
3. **Use moveToOutput**: Avoid manual path construction
4. **Consider separability**: Use `dontBuildDev` when appropriate
5. **Document outputs**: Comment what each output contains

## Troubleshooting

### Files in Wrong Output

Use `moveToOutput` to correct:

```nix
postInstall = ''
  # Move misplaced files
  moveToOutput "share/man" "$doc"
  moveToOutput "include" "$dev"
'';
```

### Missing Dependencies

Some packages expect all outputs available:

```nix
buildInputs = [
  # Force all outputs available
  pkgs.gtk3
];
```

## Summary

- Multiple outputs split a derivation into separate store paths
- Use `outputs = ["out" "dev" "doc"]` to define
- Environment variables: `$out`, `$doc`, `$dev`, `$bin`, etc.
- `bin` output's bin directory is added to PATH automatically
- Benefits: smaller closures, faster deployments, cleaner systems
- Use `moveToOutput` helper to organize files
- Nixpkgs packages commonly use multiple outputs

## Next Capsule

In the final capsule, we'll explore **fetching sources**—how to download and verify sources using fetchurl, fetchFromGitHub, and other fetch helpers.

```nix
# Next: ./pages/20-fetching-sources.md
```
