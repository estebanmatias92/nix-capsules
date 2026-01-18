# Nix Capsules 20: Basic Dependencies and Hooks

## Introduction

Welcome to the twentieth and final Nix capsule. In the previous capsule, we explored stdenv. In this capsule, we'll explore **dependencies and hooks**—how packages depend on each other and influence their dependents through the Nix build system.

Understanding dependencies is crucial for packaging complex software that relies on libraries, tools, and runtime assets.

## Dependency Types in stdenv

stdenv provides several dependency attributes:

| Attribute | Purpose | Available During |
|-----------|---------|------------------|
| `buildInputs` | Runtime dependencies | configure, build, install, fixup |
| `nativeBuildInputs` | Build-time tools | configure, build, install |
| `propagatedBuildInputs` | Inherited by dependents | configure, build, install |
| `checkInputs` | Test dependencies | check phase only |

## buildInputs

Use `buildInputs` for libraries or programs your package needs at runtime:

```nix
{ stdenv, lib, gd, libpng }:

stdenv.mkDerivation {
  name = "graphviz";
  src = ./graphviz.tar.gz;

  buildInputs = [ gd libpng ];
}
```

These packages are:
- Added to `$PATH` during build phases
- Available during runtime of the built program
- Automatically included in the runtime closure

## nativeBuildInputs

Use `nativeBuildInputs` for tools needed only during the build:

```nix
{ stdenv, pkg-config, gettext }:

stdenv.mkDerivation {
  name = "mypackage";
  src = ./mypackage.tar.gz;

  nativeBuildInputs = [ pkg-config gettext ];
}
```

These are available during build but not included in runtime dependencies.

## The PATH Setup

`stdenv` automatically adds dependencies to PATH:

```bash
export PATH="$dir/bin${PATH:+:}$PATH"
```

Each `buildInput` and `nativeBuildInput` has its `bin` directory added.

## propagatedBuildInputs

Use `propagatedBuildInputs` when dependents need the dependency:

```nix
# libfoo.nix
stdenv.mkDerivation {
  name = "libfoo";

  buildInputs = [ bar ];

  propagatedBuildInputs = [ bar ];
}
```

If `libfoo` has `bar` in `propagatedBuildInputs`, packages depending on `libfoo` automatically get `bar` in their build environment.

## How Propagation Works

When a package is built, its `propagatedBuildInputs` are recorded:

```bash
# In the fixup phase
echo "$propagatedBuildInputs" > $out/nix-support/propagated-build-inputs
```

Other packages read this file and include those dependencies.

## Example: Library Chain

```nix
# application.nix
{ stdenv, libfoo }:

stdenv.mkDerivation {
  name = "application";

  buildInputs = [ libfoo ];
}
```

If `libfoo` has `propagatedBuildInputs = [ bar ]`, then `application` automatically gets `bar` in its environment.

## Setup Hooks

Setup hooks allow packages to influence the build environment of dependents:

```bash
# In libfoo's $out/nix-support/setup-hook.sh
addToSearchPath PATH $out/bin
```

When another package includes `libfoo`, this hook is sourced automatically.

## Creating Setup Hooks

Add a setup hook in your package:

```nix
{ stdenv, writeText }:

stdenv.mkDerivation {
  name = "mylib";
  # ...

  installPhase = ''
    mkdir -p $out/nix-support
    cat > $out/nix-support/setup-hook.sh << 'EOF'
addToSearchPath() {
  local varName="\$1"
  local dir="\$2"
  if [[ ":\$${varName}:" != *":\$dir:"* ]]; then
    export "${varName}=\${dir}\${${varName}+:\${${varName}:}}"
  fi
}
EOF
  '';
}
```

## Environment Hooks

Environment hooks run for each dependency and can influence sibling dependencies:

```bash
# In a package's setup hook
envHooks+=(myEnvHook)

myEnvHook() {
  local pkg="$1"
  if [[ -f "$pkg/lib/pkgconfig/foo.pc" ]]; then
    export PKG_CONFIG_PATH="$pkg/lib/pkgconfig:$PKG_CONFIG_PATH"
  fi
}
```

This enables pkg-config auto-detection for libraries.

## The C Compiler Wrapper

The GCC/Clang wrapper uses environment hooks to set compile flags:

```nix
{ stdenv, gcc, lib }:

stdenv.mkDerivation {
  name = "gcc-wrapper";

  # The wrapper automatically sets:
  # NIX_CFLAGS_COMPILE = "-I$out/include -L$out/lib"
  # NIX_LDFLAGS = "-L$out/lib -rpath=$out/lib"
}
```

## Dependency Best Practices

1. **Use buildInputs** for runtime dependencies
2. **Use nativeBuildInputs** for build-time tools
3. **Use propagatedBuildInputs** for libraries that dependents need
4. **Create setup hooks** for non-standard configuration
5. **Minimize dependencies**—only add what you need

## Example: Complete Package with Hooks

```nix
{ stdenv, lib, pkg-config, gd, zlib }:

stdenv.mkDerivation {
  name = "mylib-1.0";

  src = ./mylib.tar.gz;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ gd zlib ];

  configureFlags = [
    "--with-gd=${gd}"
    "--with-zlib=${zlib}"
  ];

  postInstall = ''
    # Create pkg-config file
    mkdir -p $out/lib/pkgconfig
    cat > $out/lib/pkgconfig/mylib.pc << EOF
prefix=$out
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: mylib
Description: My library
Version: 1.0
Libs: -L\${libdir} -lmylib
Cflags: -I\${includedir}
EOF
  '';
}
```

## Debugging Dependencies

Check what dependencies a package has:

```bash
# Runtime dependencies
nix path-info --json /nix/store/...-mypackage | jq -r '.[].references[]'

# Build dependencies
nix derivation show /nix/store/...-mypackage.drv | jq '.[].inputDrvs'

# Environment in nix develop
nix develop .#mypackage --command env | grep -E '^(PATH|PKG_CONFIG|NIX_)'
```

## Summary

- `buildInputs` adds runtime dependencies to PATH and closure
- `nativeBuildInputs` adds build-time tools only
- `propagatedBuildInputs` makes dependencies available to dependents
- Setup hooks run automatically when packages are included
- Environment hooks allow packages to influence sibling dependencies
- Use pkg-config, setup hooks, and environment hooks for proper integration

## Conclusion

Congratulations! You've completed the Nix Capsules series. You now understand:

- The Nix expression language (types, functions, imports)
- How derivations work and how to build packages
- Generic builders and stdenv conventions
- Package composition patterns (inputs, callPackage, override)
- Search paths, store paths, and garbage collection
- Dependencies and hooks for complex packages

With this foundation, you're ready to:
- Create your own Nix packages
- Use flakes for project management
- Understand and modify nixpkgs
- Set up development environments with `nix develop`

Continue exploring the Nix ecosystem—the community is active and helpful!

```nix
# End of Nix Capsules
# For more, see:
# - Nix Manual: https://nix.dev/manual/nix
# - Nixpkgs Manual: https://nixos.org/manual/nixpkgs
# - NixOS Wiki: https://nixos.org/wiki
```
