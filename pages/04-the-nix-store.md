# Nix Capsules 4: The Nix Store

## Introduction

In the previous capsule, we installed Nix and ran our first commands. Now we'll explore the **Nix Store**—the heart of the system and the mechanism that makes "reproducibility" possible.

The Nix Store (`/nix/store`) is where everything lives. Unlike traditional package managers that scatter files into `/usr/bin`, `/usr/lib`, and `/etc`, Nix stores every version of every package in its own isolated directory.

## The Store Path Structure

Every item in the Nix Store follows a strict naming convention:

```bash
/nix/store/[hash]-[name]-[version]/
```

Examples:

```bash
/nix/store/3sg4bhqws9rx6a0b0z4q6r8c6v5m3w4x-hello-2.12.1/
/nix/store/naxm4k6xz9fh0v3b2p8c4r7z0y5q1d9s-glibc-2.38/
```

## How the Hash is Computed (The "Input" Model)

This is the most critical concept to understand: **The hash is computed from the inputs, not the output.**

Nix calculates the hash based on:

1. The source code.
2. The build script (instructions).
3. The hashes of all dependencies (compiler, libraries, shell).
4. The system architecture (e.g., `x86_64-linux`).

If you change **one character** in a comment in your source code, the input hash changes. Consequently, Nix will build a **new** store path. This ensures that if a package has the same hash, it was built in the exact same way.

## Why This Matters

### 1. Coexistence (The "Dependency Hell" Solver)

Since every variation has a unique hash, you can have multiple versions of the same library installed simultaneously.

- `Project A` can use `openssl-1.1` (Hash A).
- `Project B` can use `openssl-3.0` (Hash B).
  They do not conflict because they live in different directories.

### 2. Atomic Upgrades & Rollbacks

Upgrading a package doesn't overwrite files; it just installs the new path and updates a symlink. If the new version fails, you just point the symlink back to the old path.

### 3. Binary Caching

Because the hash is based on inputs, Nix can check a remote server: _"Do you have the binary for hash `3sg4...`?"_ If yes, it downloads it. If no, it builds it locally.

## The Dependency Graph

The Nix Store is not just a list of files; it is a **Graph**.

When a program is built, it links to specific store paths.

- The `hello` binary doesn't look for `/lib/libc.so.6`.
- It looks for `/nix/store/naxm...-glibc-2.38/lib/libc.so.6`.

This is called **Runtime Dependency Scanning**. Nix scans the binary for text strings that look like store paths and "locks" those dependencies to the package.

## Inspecting the Store

You can use standard Linux tools, but Nix provides specialized commands.

### List contents

```bash
ls /nix/store | grep hello
```

### Inspect a specific path

Use `nix path-info` to see size and details:

```bash
# Get the full path of the 'hello' executable currently in your path
which hello
# Output: /nix/store/3sg4...-hello-2.12.1/bin/hello

# Check its size and closure size (total size of dependencies)
nix path-info -Sh /nix/store/3sg4...-hello-2.12.1
```

### Inpect a specific package's dependency graph

```bash
# Check the runtime dependencies for a package
nix-store -q --tree /nix/store/3sg4...-hello-2.12.1

# Check the build-time dependencies (derivation dependencies)
nix-store -q --tree /nix/store/yni2...hello-2.12.1.drv
```

## Immutability

The Nix Store is **Read-Only**.

```bash
# This will fail
echo "hacking" > /nix/store/3sg4...-hello-2.12.1/bin/hello
# Output: Permission denied
```

This prevents "drift." You cannot accidentally delete a library that another package relies on. The only way to modify the store is via the **Nix Daemon**, which manages builds and garbage collection.

## Summary

- **Structure:** `/nix/store/<hash>-<name>`.
- **Input-Addressed:** The hash is calculated from the recipe (source + deps), ensuring that "Same Inputs = Same Output."
- **Isolation:** Dependencies are hard-coded paths; no "DLL Hell."
- **Immutability:** You cannot manually edit files in the store.

## Next Capsule

Now that we understand where files go, we need to learn the language used to describe them.

> **[Nix Capsules 5: The Basics of the Language](./05-basics-of-language.md)**
