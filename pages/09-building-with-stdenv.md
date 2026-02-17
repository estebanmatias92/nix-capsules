# Nix Capsules 9: Building with stdenv

## Introduction

In the previous capsule, we wrote a builder script from scratch. While educational, that is rarely done in practice.

Most software follows a standard lifecycle: **Unpack** source → **Configure** build → **Compile** → **Install**.

Nix provides a **Standard Environment** (`stdenv`) that automates this entire pipeline. It includes standard tools (GCC, Make, Coreutils) and a generic builder that knows how to handle standard Makefiles and Autotools projects automatically.

## What is stdenv?

`stdenv` is a derivation that provides:

1. **A Standard Shell:** Populated with common tools (`ls`, `cp`, `grep`, `make`, `gcc`).
2. **A Generic Builder:** A script that iterates through standard build phases.
3. **System Setup:** Variables like `$out`, `$src`, and `$PATH` are pre-configured.

Most packages in Nixpkgs use `stdenv.mkDerivation`.

## The Standard Pipeline (Phases)

When you run `stdenv.mkDerivation`, it executes the following **Phases** in order. If you don't write a custom builder, this happens automatically:

1. **unpackPhase**: Finds your `src` (tarball, zip, git), extracts it, and `cd`s into it.
2. **patchPhase**: Applies any patches listed in the `patches` attribute.
3. **configurePhase**: Checks for a `./configure` script. If found, runs it with standard flags (e.g., `--prefix=$out`).
4. **buildPhase**: Runs `make` (or checks for a `Makefile`).
5. **checkPhase**: Runs `make check` (if enabled).
6. **installPhase**: Runs `make install`.
7. **fixupPhase**: Nix-specific magic. It strips debugging symbols (to save space) and patches binaries (RPATH) to ensure they find their libraries in the Nix Store.

## Example 1: The Zero-Config Build

The power of `stdenv` is that for standard GNU-compliant software, **you often don't need to write any build scripts**.

We will build **GNU Hello** from its source tarball.

### `flake.nix`

```nix
{
  description = "Nix Capsule 9: stdenv Demo";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    packages.${system} = {

      # The "Magic" Default
      # Nix will automatically unpack, configure, make, and install this.
      default = pkgs.stdenv.mkDerivation {
        name = "hello-2.12.1";

        src = pkgs.fetchurl {
          url = "https://ftp.gnu.org/gnu/hello/hello-2.12.1.tar.gz";
          sha256 = "sha256-jZkUKv2SV28wsM18tCqNxoCZmLxdYH2Idh9RLibH2yA=";
        };
      };
    };
  };
}
```

### Run it

```bash
./result/bin/hello
```

**What happened?**
We didn't write a `buildPhase` or `installPhase`.

1. **Unpack:** Nix saw `.tar.gz`, extracted it, and entered `hello-2.12.1/`.
2. **Configure:** Nix found `./configure`, ran it with `--prefix=/nix/store/...`.
3. **Build:** Nix found `Makefile`, ran `make`.
4. **Install:** Nix ran `make install`.

## Example 2: Customizing Phases

Sometimes you need to tweak the process. You can inject commands **before** or **after** any phase using hooks (e.g., `preBuild`, `postInstall`), or override the phase entirely.

Let's modify the previous example to:

1. Disable the test suite (`checkPhase`).
2. Add a custom alias after installation (`postInstall`).

```nix
# ...

custom = pkgs.stdenv.mkDerivation {
  name = "hello-custom";

  src = pkgs.fetchurl {
    url = "https://ftp.gnu.org/gnu/hello/hello-2.12.1.tar.gz";
    sha256 = "sha256-jZkUKv2SV28wsM18tCqNxoCZmLxdYH2Idh9RLibH2yA=";
  };

  # 1. Configuration Flags
  # Pass arguments to the ./configure script
  configureFlags = [ "--disable-nls" ]; # Disable Native Language Support

  # 2. Control Phases
  doCheck = false; # Skip the 'make check' phase

  # 3. Inject Custom Logic
  # This runs AFTER the standard 'make install'
  postInstall = ''
    echo "Running custom post-install steps..."
    ln -s $out/bin/hello $out/bin/hi
  '';
};

# ...
```

### Run this with

```bash
nix build .#custom

./result/bin/hi
# Hello, world!
```

## Common Environment Variables

Inside the build environment, `stdenv` provides several variables you should use:

- `$out`: The installation path (e.g., `/nix/store/...-name`). **Always install here.**
- `$src`: The path to the unpacked sources.
- `$pname` / `$version`: Defined if you use those attributes in the derivation.

## Managing Dependencies

Nix forces a strict separation between **tools** (programs you run) and **libraries** (code you link against). This distinction exists to support cross-compilation (e.g., building ARM software on an x86 machine), but you must respect it even for standard builds.

You must assign your dependencies to the correct attribute:

### 1. `nativeBuildInputs` (The Tools)

Dependencies that must run on the **Build Machine** (the computer compiling the code).

- **What goes here:** Compilers, build systems, linters, and CLI utilities (`gcc`, `cmake`, `pkg-config`, `git`, `python3`).
- **The Effect:** Nix adds these packages to the `$PATH` inside the build environment.

### 2. `buildInputs` (The Libraries)

Dependencies that must exist on the **Host Machine** (where the resulting binary will run).

- **What goes here:** Libraries, headers, and runtime components (`openssl`, `zlib`, `glibc`, `libpng`).
- **The Effect:** Nix adds these to environment variables like `$C_INCLUDE_PATH`, `$LD_LIBRARY_PATH`, and `$PKG_CONFIG_PATH` so the compiler can find them.

### Example: A Complex Build

```nix
{
# ...

pkgs.stdenv.mkDerivation {
  name = "complex-app-1.0";
  src = ./src;

  # TOOLS: "I need to execute these commands to build the software"
  nativeBuildInputs = [
    pkgs.cmake       # To configure the project
    pkgs.pkg-config  # To find libraries
    pkgs.git         # To read version info
  ];

  # LIBRARIES: "My code needs to link against these files"
  buildInputs = [
    pkgs.openssl     # Provides ssl.h and libssl.so
    pkgs.zlib        # Provides zlib.h and libz.so
  ];

  # ...
}
```

> **Key Takeaway:** If a dependency fails with "command not found," you probably forgot to put it in `nativeBuildInputs`. If it fails with "header not found" or "linker error," it belongs in `buildInputs`.

## Summary

1. **`stdenv` is the standard:** It provides the GCC toolchain, Make, and the default builder.
2. **Phases are automatic:** Unpack → Patch → Configure → Build → Check → Install → Fixup.
3. **Zero-Config:** If a project follows standard Make/Autotools conventions, `mkDerivation` + `src` is often enough.
4. **Hooks:** Use `preX` / `postX` (e.g., `postInstall`) to run custom commands without rewriting the whole phase.

## Next Capsule

Now that we can build software, how does Nix ensure it finds the right libraries at runtime? In the next capsule, we explore the magic of **Automatic Runtime Dependencies**.

> **[Nix Capsules 10: Automatic Runtime Dependencies](./10-automatic-runtime-dependencies.md)**
