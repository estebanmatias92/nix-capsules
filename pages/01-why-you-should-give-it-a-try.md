# Nix Capsules 1: Why You Should Give it a Try

## Introduction

Welcome to the first post of the updated "Nix Pills" series. Nix is a purely functional package manager and deployment system for POSIX.

There is abundant documentation describing what Nix, NixOS, and related projects are. The purpose of this post is to demonstrate _why_ you should give Nix a try. Installing NixOS is not required, though we may refer to it as a real-world example of using Nix to build an entire operating system.

## Rationale for this series

The official manuals for Nix, Nixpkgs, and NixOS, along with the NixOS Wiki, are excellent resources. However, newcomers often find the underlying mechanisms—the "magic" occurring in the Nix store—difficult to grasp initially.

This series aims to complement formal documentation by breaking down these concepts. We will update the classic examples to reflect modern Nix usage, including the **experimental CLI** (the `nix` command), **Flakes**, and **Home Manager**.

### Not being purely functional

Traditional package managers (like `dpkg`, `rpm`, `apt`, or `dnf`) mutate the global state of the system. If a package `foo-1.0` installs a binary to `/usr/bin/foo`, you cannot install `foo-1.1` simultaneously unless you alter installation paths or binary names, which breaks consumers of that binary.

While mechanisms like Debian's _alternatives_ system attempt to mitigate this, they are often insufficient for complex scenarios.

Consider needing two versions of a service, such as `nginx` and `nginx-openresty`, or two versions of a database like MySQL 8.0 and MariaDB 10.11. You would typically need to patch packages to avoid file collisions or manage conflicting shared libraries. This is inconvenient and error-prone.

From an **administrator's perspective**, the modern solution is often containerization (Docker, Podman). While effective, this shifts the problem to a different layer, introducing orchestration complexity, image management, and opaque binary blobs.

From a **developer's perspective**, tools like `virtualenv` (Python), `nvm` (Node), or `rustup` (Rust) manage language-specific versions. However, mixing stacks (e.g., a Python project binding to C libraries) brings back dependency hell. You must ensure system libraries match what your development environment expects.

Nix solves these issues at the packaging level—a single tool for all dependencies.

### Being purely functional

Nix makes no assumptions about the global state. The core of the system is the **Nix store**, typically located at `/nix/store`.

In Nix, we speak of **derivations** rather than just packages. A derivation is a build recipe. Its output is stored in a path like `/nix/store/«hash»-name`.

- The **hash** uniquely identifies the entire graph of dependencies and build instructions.
- The **name** is for human readability.

For example, a `bash` derivation might result in:
`/nix/store/s4zia7hhqkin1di0f187b79sa2srhv6k-bash-5.2-p15/`

This directory is self-contained. There is no `/bin/bash` in the traditional sense; binaries are only exposed to your user environment (via your `$PATH`) when explicitly requested.

Everything in the Nix store is **immutable**.

Consider `ldd` on a Nix-managed bash binary:

```bash
$ ldd $(which bash)
libc.so.6 => /nix/store/94n64qy...-glibc-2.38/lib/libc.so.6
```

This binary is hard-linked to the exact version of `glibc` it was built against. You can have another software using an older `glibc` in the same system without conflict. Nix resolves dependencies structurally, not by version numbers.

### Mutable vs. Immutable

In mutable systems, upgrading a library like `openssl` replaces the file in-place. Applications link dynamically to the new version immediately—sometimes causing breakage if the ABI changed.

In Nix, "upgrading" `openssl` creates a **new derivation**. Existing applications continue to point to the old `openssl` path in the store until they are rebuilt against the new version. This ensures atomic upgrades and rollbacks.

- **Security updates:** Nix handles this via functional replacement (and mechanisms like runtime dependency rewriting for speed), but the principle remains: old and new coexist until the switch is finalized.
- **Runtime composition:** Some software expects plugins in global paths (e.g., Firefox finding Flash in the past). In Nix, we "wrap" binaries to explicitly set environment variables (like `MOZ_PLUGIN_PATH`) pointing to the specific store paths of dependencies. This makes the dependency graph explicit.

There is no "upgrade" or "downgrade" in the traditional sense. You simply switch your environment to a new state derived from a new set of inputs.

## Conclusion

Nix allows you to compose software with maximum flexibility and reproducibility. With the advent of **Nix Flakes**, this reproducibility extends to the project evaluation level, locking every input (nixpkgs commits, specific library versions) in a `flake.lock` file.

Deployment becomes consistent. Tools like **Colmena**, **deploy-rs**, or **nixos-rebuild** allow you to deploy entire system configurations declaratively, rendering traditional configuration management tools (Ansible, Chef) largely redundant for NixOS systems.

While Nix has a learning curve regarding the language and the override patterns, the stability and control it provides are unmatched.

## Summary

- Nix uses a purely functional approach to package management
- The Nix store (`/nix/store`) contains immutable, self-contained package derivations
- Dependencies are resolved structurally via hashes, not version numbers
- Nix enables atomic upgrades and rollbacks by creating new store paths
- Modern Nix uses flakes for reproducible project-level management

## Next Capsule

In the next post, we will install Nix on your current operating system (Linux or macOS) using the modern, recommended installation methods.

```nix
# Next: ./02-install-on-your-running-system.md
```
