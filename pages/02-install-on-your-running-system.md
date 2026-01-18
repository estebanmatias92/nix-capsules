# Nix Capsules 2: Install on Your Running System

## Introduction

In this capsule, we will install the Nix package manager on your existing operating system (Linux or macOS). We will focus on the **Multi-user installation**, which is the recommended standard.

Unlike the "Single-user" mode of the past, the Multi-user installation introduces a build daemon. This ensures that builds are performed in an isolated environment, preventing them from affecting or accessing your user’s private data during the build process.

### The Installation

The most reliable way to install Nix today, ensuring all modern features (like Flakes) are ready to use, is often via the **Determinate Systems installer** or the official installer configured with flags.

For a standard, official approach that sets up the daemon:

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

_Note: On Linux, this requires `systemd` and `sudo`. On macOS, it manages build users and volumes automatically._

### Enabling Modern Features (Flakes)

By default, the stable Nix installer might not enable the experimental unified CLI and Flakes. To use the modern interface (commands like `nix shell`, `nix build`, `nix run`), you must enable them.

Edit (or create) the configuration file at `/etc/nix/nix.conf` and add:

```ini
experimental-features = nix-command flakes
```

Restart the nix-daemon to apply changes:

- **Linux (systemd):** `sudo systemctl restart nix-daemon`
- **macOS:** `sudo launchctl kickstart -k system/org.nixos.nix-daemon`

## Components of the Installation

Once installed, Nix creates several key components on your system. Understanding these is crucial for "demystifying" the tool.

1. The Store (/nix/store)

   This is where all packages (derivations) and their dependencies reside.
   - It is **read-only** for normal users.
   - Only the **Nix Daemon** can write to it.
   - Unlike `/usr/bin`, files here are stored with hashes, e.g., `/nix/store/bw4...-firefox-120.0`.

2. The Database (/nix/var/nix/db)

   Nix uses a SQLite database to track the valid paths in the store and the relationships between them (dependencies). It is the source of truth for the package manager.

3. The Daemon and Build Users

   The installer created several system users (usually named nixbld1, nixbld2, etc.). When you run a command like nix build, your user sends a request to the Nix Daemon. The daemon delegates the build task to one of these build users.
   - **Why?** This ensures the build is hermetic. The build process cannot access your `$HOME` or other system files unless explicitly permitted.

4. The Profile (~/.nix-profile)

   Packages you install explicitly are made available to your shell via your profile.
   - Technically, `~/.nix-profile` is a symlink to a generation in `/nix/var/nix/profiles/per-user/<user>/`.
   - This profile directory contains a `bin/` folder, which is added to your `$PATH`.

## First Run: The Modern Way

Let's verify the installation. In the past, we used `nix-env`. While `nix-env` still exists, the modern equivalent for running ad-hoc software is `nix run` or `nix shell`.

Check your version:

```bash
$ nix --version
nix (Nix) 2.18.1  # Or newer
```

Now, let's run a program without "installing" it permanently into your global environment. We will use `nixpkgs#hello` (The "Hello World" of package management).

```bash
$ nix run nixpkgs#hello
Hello, world!
```

What happened here?

1. **Resolution:** Nix looked up `hello` in the `nixpkgs` flake registry.
2. **Download/Build:** It checked if the derivation for `hello` was in your `/nix/store`. If not, it fetched the binary from the configured binary cache (usually `cache.nixos.org`).
3. **Execution:** It ran the binary directly from the store.

If you inspect the store, you will find it there:

```bash
$ ls -d /nix/store/*hello*
/nix/store/mn5...-hello-2.12.1
```

## Uninstalling

Because Nix is self-contained in `/nix`, uninstalling it is mostly about removing that directory and the system hooks (daemon service, users). The installer script provided by Determinate Systems includes a robust `/nix/nix-installer uninstall` tool. If you used the official script, you must refer to the manual steps in the Nix documentation to remove the services and users safely.

## Summary

You now have a functional Nix installation with the **Daemon** active and **Flakes** enabled. You can run software ephemerally (`nix run`), and your system remains clean.

## Next Capsule

In the next capsule, we will dive into the **Nix Store** mechanics, understanding exactly how paths are computed and what goes into that hash.
