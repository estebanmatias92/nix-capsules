# Nix Capsules 3: Enter the Environment

## Introduction

In the previous capsule, we installed Nix. Now, we will explore how to manipulate the user environment.

In the classic Nix workflow, users relied on `nix-env` (imperative management). The modern CLI separates concerns into two distinct workflows:

1. **Ephemeral environments:** Using tools temporarily without installing them (`nix shell`).
2. **Persistent profiles:** "Installing" tools into your path for long-term use (`nix profile`).

This capsule focuses on how Nix constructs these environments and the "Time Machine" feature (Generations) that makes Nix unique.

## Ephemeral Environments (`nix shell`)

Before installing anything permanently, it is considered best practice in the modern Nix ecosystem to use tools ephemerally. This keeps your user profile clean and avoids "dependency rot."

The `nix shell` command spawns a **new subshell** with the requested packages added to the `PATH`.

```bash
# Enter a shell with 'gnugrep' and 'hello' available
nix shell nixpkgs#gnugrep nixpkgs#hello
```

Inside this new shell instance, the binaries are available, but they are **not** installed to your user profile.

```bash
$ which hello
/nix/store/mi08...-hello-2.12.1/bin/hello
```

Once you exit this shell (`exit` or `Ctrl+D`), the environment reverts. The package remains in the Nix Store (cached on disk) but is no longer "visible" to you.

## Persistent Environments (`nix profile`)

When you need a tool available globally in every terminal session (like your text editor, git, or starship), you use `nix profile`. This is the modern successor to `nix-env`.

### Installing a Package

To install packages, we target their Flake attributes. Let's install `hello` (for testing) and `nixd` (a language server) in a single transaction.

```bash
nix profile add nixpkgs#hello nixpkgs#nixd
```

### The Symlink Chain (How it works)

This is the most important architectural concept to grasp. Nix does **not** copy files to `/bin` or `/usr/bin`. It builds a **Symlink Forest**.

If you trace the symlinks (`readlink -f`, `ls -ld`), you will see the exact chain that connects your command line to the immutable store.

This will vary depending your system's state, but here is an example of the resolution path for `hello` in **Generation 1**:

1. **The User Link:**
   `~/.nix-profile` → `~/.local/state/nix/profiles/profile`
   _(This is a stable pointer to your active profile)_
2. **The Active Generation:**
   `.../profiles/profile` → `profile-1-link`
   _(Nix atomically updates this single link when you switch generations)_
3. **The Store Object:**
   `profile-1-link` → `/nix/store/ss76...-profile`
   _(This directory contains the union of all your installed packages)_
4. **The Binary:**
   `/nix/store/ss76...-profile/bin/hello` → `/nix/store/mi08...-hello-2.12.1/bin/hello`
   _(The actual executable)_

When you modify your profile (add/remove), Nix creates a new generation (e.g., `profile-2-link`) and simply points step #2 to it.

### Deep Dive: The Manifest (`manifest.json`)

Unlike traditional package managers that just dump files, `nix profile` maintains a rigorous state database inside every profile generation. This file is located at `~/.local/state/nix/profiles/profile-1-link/manifest.json`.

This JSON file is the "Brain" of the operation. It tracks exactly what is installed and, crucially, **where it came from**.

```json
{
  "elements": {
    "hello": {
      "active": true,
      "attrPath": "legacyPackages.x86_64-linux.hello",
      "storePaths": ["/nix/store/mi08...-hello-2.12.1"],
      "url": "github:NixOS/nixpkgs/ab9fbbcf485...?narHash=..."
    },
    "nixd": {
      "active": true,
      "attrPath": "legacyPackages.x86_64-linux.nixd",
      "url": "github:nixos/nixpkgs/7d1bd4fe...?narHash=..."
    }
  },
  "version": 3
}
```

- **`attrPath`**: Remembers that you asked for `hello`.
- **`storePaths`**: The exact immutable path currently linked.
- **`url`**: The **locked commit hash** of nixpkgs used at the moment of installation. This ensures strict reproducibility.

### Listing & Removing

To see what is installed, use the list command. Note that modern Nix identifies packages by Name and Attribute.

```bash
$ nix profile list

Name:               hello
Flake attribute:    legacyPackages.x86_64-linux.hello
Original flake URL: flake:nixpkgs
Locked flake URL:   github:NixOS/nixpkgs/ab9fbbcf4858bd6d40ba2bbec37ceb4ab6e1f562?narHash=sha256-mAdJpV0e5IGZjnE4f/8uf0E4hQR7ptRP00gnZKUOdMo%3D
Store paths:        /nix/store/mi08jhbcjib1i1kgvbd0fxn2yrnzdv4a-hello-2.12.1

Name:               nixd
Flake attribute:    legacyPackages.x86_64-linux.nixd
Original flake URL: github:nixos/nixpkgs
Locked flake URL:   github:nixos/nixpkgs/7d1bd4fecd676c91d160caba927f1f024f11807b?narHash=sha256-wftfEnqn%2BtUyBQIJihqanLjAvSUztRqYMsZ43Uxhf2M%3D
Store paths:        /nix/store/zshah9c3gzvmra5s4gg7901kvf0wv824-nixd-2.8.2
```

To remove a package, you must match it by its name or store path:

```bash
# Remove by name
nix profile remove hello

# OR remove by store path (if you have multiple 'hello's)
nix profile remove /nix/store/...-hello-2.12.1
```

### Upgrading

To update all packages in your profile to the latest version locked in the flake registry:

```bash
nix profile upgrade --all
```

## Generations and History

Because each operation creates a new generation (with its own `manifest.json`), `nix profile history` works by simply comparing the manifests of consecutive generations.

### 1. **Check History:**

The history shows the **deltas** (what changed) between versions.

```bash
$ nix profile history
Version 1 (2026-01-23):
  flake:nixpkgs#legacyPackages.x86_64-linux.hello: 2.12.2 added
  flake:nixpkgs#legacyPackages.x86_64-linux.nixd: 2.8.2 added

Version 2 (2026-01-23) <- 1:
  flake:nixpkgs#legacyPackages.x86_64-linux.hello: 2.12.2 removed
```

### 2. **Rollback:**

If you break your environment, you can instantly revert.

```bash
nix profile rollback
```

This simply points the `profile` symlink back to `profile-1-link`.

> **Warning: Don't Cross the Streams**
> Do not mix `nix-env` (old command) with `nix profile` (new command). They try to manage the same symlink profile and will conflict. Stick to `nix profile` for the modern experience.

## Summary

- **`nix shell`**: Temporary subshell. Best for one-off tasks.
- **`nix profile`**: Persistent installation. Modifies `~/.nix-profile`.
- **Manifest**: The `manifest.json` file tracks the exact state and origin of every package.
- **Generations**: Every change creates a new generation ID (`profile-N-link`).
- **Rollback**: You can instantly revert to any previous state by switching the profile symlink.

## Next Capsule

In the next capsule, we will dive deep into the **Nix Store** mechanics, understanding exactly how those weird `/nix/store/mi08...` paths are computed.

> **[Nix Capsules 4: The Nix Store](./04-the-nix-store.md)**
