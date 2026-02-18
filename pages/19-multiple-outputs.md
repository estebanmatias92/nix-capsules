# Nix Capsules 19: Multiple Outputs

## Introduction

In the previous capsule, we looked at Store Internals and the dependency graph. Now, we'll tackle a practical problem that arises when packaging complex software: **Closure Bloat**.

When you compile a typical software project, the build produces:

1. Runtime binaries.
2. C headers (`.h`) for development.
3. Documentation files (HTML/Man pages).

If you dump all of this into the default `$out` path, anyone who installs your package will be forced to download the headers and documentation, even if they only want to run the program. Nix solves this using **Multiple Outputs**.

## The Bloated Closure Trap (Fail-First)

Let's build a package that generates a tiny binary but also creates a massive 50MB "documentation" file.

**File:** `flake.nix`

```nix
{
  description = "Multiple Outputs Demo";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system} = rec {

      # 1. THE BLOATED APP (The Trap)
      bloated-app = pkgs.stdenv.mkDerivation {
        name = "bloated-app";
        dontUnpack = true;
        
        installPhase = ''
          mkdir -p $out/bin $out/share/doc
          
          # The tiny executable
          echo "#!${pkgs.bash}/bin/bash" > $out/bin/my-app
          echo "echo 'Running...'" >> $out/bin/my-app
          chmod +x $out/bin/my-app
          
          # The massive 50MB dummy documentation
          head -c 50M </dev/zero > $out/share/doc/manual.html
        '';
      };

      default = bloated-app;
    };
  };
}
```

**Build and Inspect:**

```bash
git init && git add flake.nix
nix build .
nix path-info -Sh ./result
```

**The Failure:**
Your app's closure size is over 50 Megabytes! Every user who depends on `bloated-app` will be forced to download that useless dummy documentation to their `/nix/store`.

## Step 1: Splitting the Outputs

To fix this, we instruct Nix to create **separate store paths** for a single build.

Add `split-app` to your `packages` set:

```nix
      # 2. THE SPLIT APP (The Fix)
      split-app = pkgs.stdenv.mkDerivation {
        name = "split-app";
        dontUnpack = true;
        
        # We declare multiple outputs. 
        # "out" is always the default.
        outputs = [ "out" "doc" ];
        
        installPhase = ''
          # Nix provides environment variables for each output!
          mkdir -p $out/bin $doc/share/doc
          
          # The executable goes to the default output ($out)
          echo "#!${pkgs.bash}/bin/bash" > $out/bin/my-app
          echo "echo 'Running...'" >> $out/bin/my-app
          chmod +x $out/bin/my-app
          
          # The massive documentation goes to the secondary output ($doc)
          head -c 50M </dev/zero > $doc/share/doc/manual.html
        '';
      };
```

**Test the Fix:**

```bash
nix build .#split-app
nix path-info -Sh ./result
```

**Success:** The size is now just a few kilobytes! By default, `nix build` only asks for the `out` output. The `doc` output was still built during the same phase and lives in your `/nix/store`, but it has been neatly separated.

## Step 2: Accessing Secondary Outputs

How do you get the documentation if you actually want it?
You explicitly request the `doc` output using the dot syntax:

```bash
# Build the documentation output specifically
nix build .#split-app.doc

# Inspect the result
ls -lh ./result/share/doc/manual.html
```

When you define `outputs = [ "out" "dev" "doc" ];`, Nix automatically adds these as attributes to your package.

* `pkgs.split-app` points to the default `out`.
* `pkgs.split-app.doc` points to the `doc` store path.

## Step 3: The Mechanism (Glass Box)

Let's look at the `.drv` file to see how Nix handles this internally.

```bash
nix derivation show .#split-app
```

**The Output:**
Look at the `outputs` object. Notice how Nix pre-calculated **two different store paths** for the exact same build:

```json
      "outputs": {
        "doc": {
          "path": "/nix/store/...-split-app-doc"
        },
        "out": {
          "path": "/nix/store/...-split-app"
        }
      },
```

If you look in the `env` object further down, you'll see how `stdenv` gets its variables:

```json
        "doc": "/nix/store/...-split-app-doc",
        "out": "/nix/store/...-split-app",
        "outputs": "out doc",
```

This is why you were able to use `$doc` in your bash script—Nix passed the pre-calculated store path as a standard environment variable into the build sandbox.

## Step 4: Stdenv Magic (`moveToOutput`)

If you are packaging standard C software (like using `make install`), the provided `Makefile` usually dumps *everything* into `$out` blindly. It doesn't know about `$doc` or Nix's output separation.

Instead of writing complex patches for every `Makefile`, `stdenv` provides a Bash helper function called `moveToOutput`. You can use it in your `postInstall` phase to clean up the mess dynamically.

```nix
  postInstall = ''
    # Move the documentation folder from $out to $doc
    moveToOutput "share/doc" "$doc"
    
    # Move C headers from $out to $dev
    moveToOutput "include" "$dev"
  '';
```

## Summary

* **The Trap:** Putting docs and headers in `$out` bloats the runtime closure of everyone who uses your software.
* **Outputs Array:** Declare `outputs = [ "out" "doc" "dev" ];` to split the build into multiple independent store paths.
* **Environment Variables:** Nix injects `$out`, `$doc`, and `$dev` pointing to the respective store paths so your build scripts can route files correctly.
* **Accessing:** Use `.#package.doc` or `pkgs.package.doc` to explicitly reference a secondary output.
* **`moveToOutput`:** A standard `stdenv` helper to shift files into their correct outputs after a messy `make install`.

## Next Capsule

In the final capsule, we'll explore **fetching sources**—how to download and verify sources using fetchurl, fetchFromGitHub, and other fetch helpers.

> **[Nix Capsules 20: Fetching Sources](./20-fetching-sources.md)**
