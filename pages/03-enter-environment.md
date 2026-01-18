# Nix Capsules 3: Enter the Environment

## Introduction

In the previous capsule, we installed Nix. Now, we will explore how to manipulate the user environment.

In the classic Nix workflow, users relied heavily on `nix-env` to install and manage packages imperatively. The modern CLI separates these concerns into two distinct workflows:

1. **Ephemeral environments:** Using tools temporarily without installing them (`nix shell`).
2. **Persistent profiles:** "Installing" tools into your path for long-term use (`nix profile`).

This capsule focuses on how Nix constructs these environments and how to manage the "generations" of your profile.

## Ephemeral Environments (`nix shell`)

Before installing anything permanently, it is considered best practice in the modern Nix ecosystem to use tools ephemerally. This keeps your user profile clean.

The `nix shell` command modifies your current shell environment (specifically the `PATH` variable) to include the requested packages.

```bash
nix shell nixpkgs#gnugrep nixpkgs#hello
```

Inside this new shell instance, the requested binaries are available.

```bash
$ which hello
/nix/store/...-hello-2.12.1/bin/hello
```

Once you exit this shell (`exit` or `Ctrl+D`), the environment reverts to its previous state, and `hello` is no longer in your path. The package remains in the Nix store (cached) but is not linked to your user profile.

## Persistent Environments (`nix profile`)

When you need a tool available globally in every terminal session (like your text editor or version control system), you use `nix profile`. This is the direct modern successor to `nix-env`.

### Installing a Package

To install a package, we target a Flake attribute (usually from `nixpkgs`).

```bash
nix profile add nixpkgs#hello
```

If you check the location of the binary now, you will see a different path structure compared to `nix shell`:

```bash
$ which hello
/home/user/.nix-profile/bin/hello
```

### The Symlink Chain

The "magic" of the Nix environment lies in how this path is constructed. Nix does not copy files to `/usr/bin` or `/bin`. Instead, it heavily utilizes symlinks.

1. `~/.nix-profile` is a symlink to the current generation of your profile, e.g., `/nix/var/nix/profiles/per-user/user/profile-42-link`.
2. That profile link points to a directory in the `/nix/store` that contains the union of all installed packages.
3. Your `$PATH` includes `~/.nix-profile/bin`.

When you run `nix profile add`, Nix builds a new user environment in the store (a new directory containing symlinks to all your installed programs) and updates `~/.nix-profile` to point to it. This operation is **atomic**.

### Listing Installed Packages

To see what is currently in your persistent profile:

```bash
$ nix profile list
Name:               hello
Flake attribute:    legacyPackages.x86_64-linux.hello
Original flake URL: flake:nixpkgs
Locked flake URL:   github:NixOS/nixpkgs/...?narHash=sha256-...%3D
Store paths:        /nix/store/...-hello-2.12.2
```

### Removing Packages

You can remove a package by referencing its name.

```bash
nix profile remove hello
```

And then verify the list again to see the changes.

```bash
nix profile list
```

## Generations and Rollbacks

One of the most powerful features of Nix is versioning the environment state. Every time you run `nix profile add` or `remove`, you create a new **generation** of your profile.

Because Nix never overwrites the previous state (files are immutable in the store), you can instantly revert to a previous configuration if an update breaks something or if you accidentally remove a package.

To see the current generations:

```bash
nix profile history
```

To roll back to the previous state:

```bash
nix profile rollback
```

You can check `nix profile history` again and see which generation your profile in referencing now.

This reliability means you can upgrade packages without fear. If the new version fails, a rollback is instant and guaranteed to restore the exact previous binary, byte-for-byte.

## Summary

- **`nix shell`** is for temporary, on-the-fly environments.
- **`nix profile`** manages your persistent user environment (symlinked to `~/.nix-profile`).
- **Generations** allow for atomic upgrades and rollbacks.
- Your environment is composed of symlinks pointing to immutable paths in the `/nix/store`.

## Next Capsule

In the next capsule, we will explore the **Nix Language** basics. To understand how to configure systems or write packages, we need to understand the syntax that drives these derivations.
