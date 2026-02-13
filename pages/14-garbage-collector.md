# Nix Capsules 14: The Garbage Collector

## Introduction

In the previous capsules, we've been building and downloading software. Every time you run `nix build`, `nix run`, or `nix develop`, items are added to the **Nix Store** (`/nix/store`).

Unlike traditional package managers that overwrite files (e.g., upgrading `python 3.9` to `3.10` deletes `3.9`), Nix **never deletes anything** unless you explicitly ask it to. This creates a "time machine," but it also fills up your hard drive.

In this capsule, we will learn how to safely reclaim space using the **Garbage Collector (GC)**.

## The Concept: Reachability

Nix uses a memory management concept called **Tracing Garbage Collection** (similar to Java or Go), but applied to the filesystem.

1. **GC Roots:** These are the "anchors." Files that are explicitly "in use."
2. **The Graph:** Nix traces all dependencies of the roots.
3. **Garbage:** Any store path that is **not reachable** from a GC Root is deleted.

## Step 1: The "Unkillable" Package (Fail-First)

Let's prove how this works. We will build a package, try to delete it, and fail.

**1. Build a package:**
Create a simple flake or use a previous one.

```bash
# Build GNU Hello
nix build nixpkgs#hello
```

This creates a symlink named `result` in your current directory pointing to the store.

**2. Verify existence:**

```bash
readlink -f result
# Output: /nix/store/mn5...-hello-2.12.1
```

**3. Try to clean up:**
Run the garbage collector.

```bash
nix store gc
```

**4. Check again:**
Does the path still exist?

```bash
ls -d /nix/store/mn5...-hello-2.12.1
# It is STILL there!
```

**Why did it fail?**
Nix didn't delete it because you are still "using" it. The `result` symlink in your folder is a **GC Root**. As long as that symlink exists, Nix guarantees the store path exists.

## Step 2: Inspection (Glass Box)

How does Nix know about your `result` link? It doesn't scan your whole hard drive; that would be too slow.

When you ran `nix build`, Nix registered a "temporary root" or an "auto root". Let's look under the hood.

```bash
# List the registered GC roots directory
ls -l /nix/var/nix/gcroots/auto/
```

You will see symlinks that point back to your project directory:

```text
lrwxrwxrwx ... 12345 -> /home/user/my-project/result

```

**The Chain of Life:**
`/nix/var/nix/gcroots/...` → `~/my-project/result` → `/nix/store/...-hello`

Because the chain is unbroken, the package lives.

## Step 3: Deleting the Root

To delete the package, we must break the chain.

**1. Remove the user link:**

```bash
rm ./result
```

**2. Run GC again:**

```bash
nix store gc
```

_Note: You might see "0 bytes freed" if other things (like your shell history or profiles) are still using `hello`. This is normal in Nix—shared dependencies are only deleted when **no one** uses them._

## Managing Profiles (The History)

The most common source of "disk bloat" is your profile history. Every time you run `nix profile upgrade`, the old versions are kept for rollback.

### Inspect History

```bash
nix profile history
```

### Clean History

To save space, you must delete old generations. This removes them as GC Roots.

```bash
# Delete all generations except the current active one
nix profile wipe-history

# Delete generations older than 7 days
nix profile wipe-history --older-than 7d
```

**Warning:** Once you wipe history, you cannot `nix profile rollback` to those versions anymore.

## The Nuclear Option (`nix-collect-garbage`)

While `nix store gc` cleans up unreferenced paths, it doesn't automatically remove old profile generations.

There is a legacy (but standard) utility that combines "wipe history" and "collect garbage" into one command.

```bash
# 1. Delete old generations (profile & system)
# 2. Run Garbage Collection
nix-collect-garbage -d
```

Use this when you want to free up maximum space.

## Visualizing Disk Usage

Before deleting things, it's useful to know what is taking up space.
We use `nix path-info` with the `-S` (closure size) flag.

```bash
# Check the size of the current folder's derivation
nix path-info -Sh .#

# Check the size of a specific tool
nix path-info -Sh nixpkgs#firefox
```

## Summary

- **GC Roots:** Symlinks that tell Nix "I need this file."
- **Safety:** Nix never deletes a file reachable from a root.
- **The `result` link:** `nix build` creates a GC root in your folder. Delete the link to free the store path.
- **Generations:** Old profile versions hold onto old packages.
- **Cleanup:**

1. `nix profile wipe-history` (Remove old roots).
2. `nix store gc` (Delete unreferenced files).

## Next Capsule

We have explored the Nix command line and language extensively. Now it is time to look at the massive library that powers it all.

> **[Nix Capsules 15: Nixpkgs Deep Dive](./15-nixpkgs-deep-dive.md)**
