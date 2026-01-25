# Nix Capsules 7: Our First Derivation

## Introduction

Welcome to the seventh Nix capsule. We have learned the language syntax. Now, we finally write our first **Derivation**.

A derivation is the atomic unit of a Nix build. It is a **recipe** that tells Nix exactly how to create a file or directory in the Nix Store.

## The `derivation` Builtin

At the lowest level, Nix provides a function called `builtins.derivation`. Every package you use (Firefox, Vim, Python) eventually calls this primitive function.

It requires three mandatory attributes:

1. **name**: What to call the package.
2. **system**: Which architecture this is for (e.g., `x86_64-linux`).
3. **builder**: The absolute path to the executable that runs the build.

## Step 1: The Broken Derivation

Let's try to build something using a modern Flake. We will intentionally make mistakes to understand how Nix thinks.

### `flake.nix`

```nix
{
  description = "My First Derivation";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    packages.${system}.default = derivation {
      name = "my-first-package";
      system = system;
      # ERROR: This file doesn't exist!
      builder = "my-builder-executable";
    };
  };
}
```

### Try to build it

```bash
nix build .
```

**The Failure:**
You will get an error like `executing 'my-builder-executable': No such file or directory`.
**Why?** Nix builds happen in a sandbox. It cannot see `/bin/bash` or `/usr/bin/make` from your host system. You must provide a builder that exists _inside the Nix store_.

## Step 2: The "Do Nothing" Derivation

We need a real program. Let's use `coreutils` from Nixpkgs, which contains the `true` command (a program that does nothing and returns success).

Update your `flake.nix`:

```nix
  #...
    packages.${system}.default = derivation {
      name = "my-second-package";
      system = system;
      # We use string interpolation to get the store path of coreutils
      builder = "${pkgs.coreutils}/bin/true";
    };
  # ...
```

### Try to build it again

```bash
nix build .
```

**The Failure:**
`builder for ... failed to produce output path for output 'out'`
**Why?** The builder ran successfully (exit code 0), but it **didn't create anything**.
Nix mandates that a derivation **must** produce a file or directory at the specific path Nix calculated for it.

## Step 3: A Working Derivation

To make it work, we need a builder that can write files. We will use `bash`.

We need to:

1. Set `bash` as the builder.
2. Pass arguments (`args`) to tell Bash what to do.
3. Write something to the environment variable `$out` (which Nix sets for us).

```nix
  #...
    packages.${system}.default = derivation {
      name = "my-third-package";
      system = system;

      # 1. The Executable
      builder = "${pkgs.bash}/bin/bash";

      # 2. The Arguments
      args = [ "-c" "echo 'Hello from Nix' > $out" ];
    };
  # ...
```

### Build it (Success!)

```bash
nix build .
```

Now check the result:

```bash
cat ./result
# Output: Hello from Nix
```

You have just manually created a package without using `stdenv` or `make`!

## Understanding `.drv` Files

When you ran `nix build`, Nix actually performed two distinct steps:

1. **Instantiation:** It evaluated your `.nix` code and created a **Derivation File** (`.drv`). This is a language-independent JSON-like file that describes the build.
2. **Realization:** It executed the `.drv` instructions to create the output.

You can see the intermediate `.drv` file without building:

```bash
# Instantiate the derivation
nix path-info --derivation .
# Output: /nix/store/...-my-third-package.drv
```

Inspect its content:

```bash
nix derivation show .
```

You will see the raw instructions Nix uses:

```json
{
  "derivations": {
    "b04ni96maz8pkgllsr90qcbbgcm8zr8h-my-third-package.drv": {
      "args": ["-c", "echo 'Hello from Nix' > $out"],
      "builder": "/nix/store/hkbylipx1iiawqdcjv858p501wv81bpm-bash-interactive-5.3p3/bin/bash",
      "env": {
        "builder": "/nix/store/hkbylipx1iiawqdcjv858p501wv81bpm-bash-interactive-5.3p3/bin/bash",
        "name": "my-third-package",
        "out": "/nix/store/cyaknv6lx5aml34nsj651ijkkmzzrmvx-my-third-package",
        "system": "x86_64-linux"
      },
      "inputs": {
        "drvs": {
          "w673c1p7yx8crv1q7xlylfzw951g6ifl-bash-interactive-5.3p3.drv": {
            "dynamicOutputs": {},
            "outputs": ["out"]
          }
        },
        "srcs": []
      },
      "name": "my-third-package",
      "outputs": {
        "out": {
          "path": "cyaknv6lx5aml34nsj651ijkkmzzrmvx-my-third-package"
        }
      },
      "system": "x86_64-linux",
      "version": 4
    }
  },
  "version": 4
}
```

Notice that the `builder` path is a full store path (e.g., `/nix/store/lw1...-bash`). Nix replaced `${pkgs.bash}` with the actual path during Instantiation.

## The `$out` Variable

How did the script know where to write?
Nix automatically sets the `$out` environment variable inside the builder sandbox. This path is calculated **before** the build runs.

- **Input:** `derivation { name = "foo"; ... }`
- **Calculation:** Hash of inputs + name.
- **Target:** `/nix/store/hash-foo`
- **Requirement:** The builder **must** create a file or directory at that exact path.

## Summary

- **`derivation`** is the low-level primitive that powers all of Nix.
- **Sandboxing:** Builders cannot see system tools; you must provide paths to store objects (like `${pkgs.bash}`).
- **The Contract:** A derivation must create the file/directory at `$out`.
- **Instantiation:** `.nix` -> `.drv` (The Plan).
- **Realization:** `.drv` -> Output (The Execution).

## Next Capsule

We've used `builtins.derivation`, but in the real world, we rarely write raw shell scripts like this. We use the **Standard Environment** (`stdenv`). But first, we need to understand the magic behind those hash strings in the store paths.

> **[Nix Capsules 8: Store Path Mechanics](./08-store-path-mechanics.md)**
