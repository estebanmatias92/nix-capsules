# Nix Capsules 20: Fetching Sources

## Introduction

Welcome to the twentieth and final Nix capsule.

So far, we have built packages using local files (`src = ./.`) or simple `fetchurl` downloads. But most software lives in version control systems like GitHub or GitLab.

In this final capsule, we will explore **Fetchers**—the functions Nix uses to securely and reproducibly download source code from the internet.

## The TOFU Trap (Fail-First)

Nix requires a cryptographic hash for any external download to ensure reproducibility (Fixed-Output Derivations). But if you are packaging a brand new GitHub repository, how can you possibly know the hash of the code before you download it?

You use a workflow called **TOFU (Trust On First Use)**. You intentionally break the build to ask Nix for the answer.

**File:** `flake.nix`

```nix
{
  description = "Fetching Sources Demo";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system} = rec {

      # 1. THE TOFU TRAP
      # We want to fetch the patchelf source code from GitHub
      source-code = pkgs.fetchFromGitHub {
        owner = "NixOS";
        repo = "patchelf";
        rev = "0.18.0"; # Always pin a specific commit or tag!
        
        # ⚠️ FAIL-FIRST: We leave the hash empty. 
        # This forces Nix to download it, compute the hash, and fail.
        hash = ""; 
      };

      default = source-code;
    };
  };
}

```

**Try to build it:**

```bash
git init && git add flake.nix
nix build .

```

**The Failure:**
Nix will download the repository, compute the hash, and abort the build with a highly useful error message:

```text
error: hash mismatch in fixed-output derivation
  specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
  got:       sha256-nO7Yk43K4M3x5B1qP/iQZ1eG6V5pW1X6R+Q8eU/uXwI=

```

## Step 1: Securing the Source

To fix the build, you simply copy the `got:` hash from the error message and paste it into your `flake.nix`:

```nix
      source-code = pkgs.fetchFromGitHub {
        owner = "NixOS";
        repo = "patchelf";
        rev = "0.18.0";
        # The true hash provided by the TOFU failure
        hash = "sha256-nO7Yk43K4M3x5B1qP/iQZ1eG6V5pW1X6R+Q8eU/uXwI="; 
      };

```

Run `nix build .` again, and it will succeed! The resulting store path will contain the raw source code of the repository.

> **Didactic Check:** Why must we use a specific tag (`rev = "0.18.0"`) instead of `rev = "main"`?
> *Because `main` changes!* If someone commits to `main` tomorrow, the contents will change, but your `flake.nix` will still be enforcing today's `hash`. The build would fail for anyone trying to reproduce it.

## Step 2: The Mechanism (Glass Box)

Many developers assume `fetchFromGitHub` runs `git clone` under the hood. It doesn't.

Let's inspect the derivation to see what Nix actually executed.

```bash
nix derivation show .#source-code

```

**The Output:**
If you look at the `builder` and `env` attributes, you will not see `git`. You will see tools related to `fetchzip` and `curl`.

**The Glass Box:** Running `git clone` downloads the entire `.git` history, which wastes massive amounts of bandwidth and storage. Instead, `fetchFromGitHub` intelligently constructs a URL to GitHub's automated tarball generator (e.g., `https://github.com/NixOS/patchelf/archive/0.18.0.tar.gz`). It downloads the archive, unpacks it, and deletes the `.git` folder metadata.

*Note: This is why the hash of `fetchFromGitHub` will not match the hash of a local `git clone`!*

## Step 3: Fetching in a Real Build

A fetcher like `fetchFromGitHub` simply returns a string pointing to the `/nix/store` path where it saved the code. Because of this, we can plug it directly into the `src` attribute of a standard `mkDerivation`.

Let's complete our `flake.nix` by actually building the C++ project we just fetched.

**File:** `flake.nix` (Completed)

```nix
{
  description = "Fetching Sources Demo";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system} = rec {

      # We fetch the source
      patchelf-source = pkgs.fetchFromGitHub {
        owner = "NixOS";
        repo = "patchelf";
        rev = "0.18.0";
        hash = "sha256-nO7Yk43K4M3x5B1qP/iQZ1eG6V5pW1X6R+Q8eU/uXwI="; 
      };

      # We build the source
      patchelf-app = pkgs.stdenv.mkDerivation {
        name = "my-patchelf";
        
        # Nix evaluates 'patchelf-source' to its store path, 
        # and stdenv automatically unpacks it!
        src = patchelf-source;
        
        # We add the tools required to build this specific project
        nativeBuildInputs = [ pkgs.autoreconfHook ];
      };

      default = patchelf-app;
    };
  };
}

```

Run `nix build .`, and you have just downloaded and compiled a real open-source project from scratch!

## Other Common Fetchers

While `fetchFromGitHub` is the most common, `nixpkgs` provides helpers for almost any scenario:

* **`pkgs.fetchurl`**: For direct single-file or tarball downloads.
* **`pkgs.fetchzip`**: Downloads an archive and automatically unzips/untars it into a directory.
* **`pkgs.fetchgit`**: Actually runs `git clone`. Use this only if you specifically need Git submodules or if the host doesn't support tarball generation.
* **`pkgs.fetchFromGitLab` / `fetchFromGitea`**: Specialized helpers for other popular forges.

## Summary

* **TOFU (Trust On First Use):** Set `hash = ""` to intentionally fail a build, letting Nix calculate the correct hash for a new download.
* **Pinning:** Never use floating tags like `main` or `latest` in fetchers. Always use immutable commit hashes or release tags.
* **The Glass Box:** `fetchFromGitHub` uses `fetchzip` under the hood to download tarballs, saving bandwidth and stripping non-deterministic `.git` folders.
* **Integration:** Fetchers return store paths. You assign them directly to the `src` attribute of `mkDerivation`.

---

## Congratulations

You now have a complete toolkit. Here's what you can build next:

### Your First Real Project

Pick a project you use daily—write its `flake.nix` using:

* `fetchFromGitHub` to fetch dependencies
* `mkDerivation` to build it
* `devShell` for development

### Continue Learning

The Nix ecosystem has specialized guides built on what you just learned:

* **Home Manager**: [nix-community.github.io/home-manager](https://nix-community.github.io/home-manager) — declarative home directory management
* **NixOS**: [nixos.org/manual/nixos](https://nixos.org/manual/nixos) — declarative system configuration
* **devenv**: [devenv.sh](https://devenv.sh/) — developer environments at scale
* **flakehub.com**: [flakehub.com](https://flakehub.com/) — deployment with flakes

### References

For ongoing documentation while you build:

* **Nix Manual**: [nix.dev/manual/nix](https://nix.dev/manual/nix) — command and language reference
* **Nixpkgs Manual**: [nixos.org/manual/nixpkgs](https://nixos.org/manual/nixpkgs) — packaging guide
* **Zero to Nix**: [zero-to-nix.com](https://zero-to-nix.com) — quick reference

You started by running binaries. Now you can fetch, build, compose, and ship.

Go build something you'll actually use.

---

*The complete series: [Nix Capsules](../README.md)*
