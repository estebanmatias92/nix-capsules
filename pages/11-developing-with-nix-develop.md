# Nix Capsules 11: Developing with `nix develop`

## Introduction

Welcome to the eleventh Nix capsule. In the previous capsule, we learned how Nix automatically detects runtime dependencies to build reproducible packages. But what if you aren't ready to package software yet? What if you just want to write code?

In traditional systems, you install tools like `gcc`, `python`, or `cmake` globally. This leads to "version hell" when two projects need different versions of the same tool.

In this capsule, we will use `nix develop` to create **ephemeral, isolated development environments**.

## The Development Shell Concept

A **Development Shell** (`devShell`) is a shell session where the `PATH` and environment variables are modified to include specific tools, but only for the duration of that session.

- **Global Install**: `sudo apt install python3` (Affects the whole OS).
- **Nix Shell**: "Give me Python 3.11 and Poetry, but only while I'm in this terminal."

## The `mkShell` Function

Just as `mkDerivation` creates a package, `mkShell` creates a development environment. It relies on the exact same dependency logic we learned in Capsule 10.

## Example: A C/C++ Development Environment

Let's create a flake that provides a compiler, a build system (Make), and a debugger, but _only_ inside our shell.

**file: `flake.nix`**

```nix
{
  description = "Nix Capsule: C Development Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    # Unlike 'packages', which builds artifacts, 'devShells' prepares environments.
    devShells.${system}.default = pkgs.mkShell {

      # 1. NATIVE BUILD INPUTS (Tools)
      # These are added to your $PATH.
      # They run on your host machine (the one you are typing on).
      nativeBuildInputs = with pkgs; [
        gcc
        gnumake
        gdb
        cowsay # Just for fun, to prove we are in the shell
      ];

      # 2. BUILD INPUTS (Libraries)
      # These are libraries your code links against.
      # Nix adds them to C_INCLUDE_PATH and LIBRARY_PATH environment variables.
      buildInputs = with pkgs; [
        zlib
        openssl
      ];

      # 3. SHELL HOOK
      # A Bash script that runs immediately when you enter the shell.
      shellHook = ''
        echo "Welcome to the Nix C-Dev Environment!"
        echo "gcc version: $(gcc --version | head -n1)"
        cowsay "Ready to code!"
      '';
    };
  };
}
```

## The "Fail-First" Workflow

To understand the isolation, try running the tools _before_ entering the environment.

1. **Fail Test**: Try to run `cowsay` (assuming you don't have it installed globally).

```bash
$ cowsay "Hello?"
bash: cowsay: command not found
```

_Why?_ The tool exists in the Nix Store, but it is not in your global `$PATH`.

1. **Enter the Shell**:

```bash
nix develop
```

You should see the startup message and the cow:

```text
Welcome to the Nix C-Dev Environment!
gcc version: gcc (GCC) 13.2.0
 _________________
< Ready to code! >
 -----------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

1. **Verify Isolation**:
   Inside the shell, run `which gcc`. It will point to a specialized store path, not `/usr/bin/gcc`.

```bash
$ which gcc
/nix/store/...-gcc-wrapper-13.2.0/bin/gcc
```

## Understanding Dependency Types

In `mkShell`, we apply the same dependency logic we learned in **Capsule 09**, but `mkShell` offers a third convenience attribute specifically for ephemeral environments.

It is crucial to choose the right bucket for your dependencies:

| Attribute               | Logic                     | Effect in Shell                                      |
| ----------------------- | ------------------------- | ---------------------------------------------------- |
| **`nativeBuildInputs`** | **Tools** (Run-time)      | Added to `$PATH`. You can run them immediately.      |
| **`buildInputs`**       | **Libraries** (Link-time) | Added to `$C_INCLUDE_PATH`, `$LD_LIBRARY_PATH`, etc. |
| **`packages`**          | **The Shortcut**          | **Alias for `nativeBuildInputs**`. Added to `$PATH`. |

### The `packages` Attribute (New!)

You will often see flakes that look like this:

```nix
devShells.default = pkgs.mkShell {
  packages = [ pkgs.nodejs pkgs.python3 ];
};
```

The `packages` attribute is syntactic sugar specific to `mkShell`. It does not exist in the standard `mkDerivation`.

- **Use `packages`:** For interpreted languages (Python, JS, Ruby) or DevOps tools (Terraform, kubectl) where you just want binaries in your `$PATH`.
- **Use `native` vs `build`:** When doing **C/C++** or compiled languages where you need strict separation between the compiler (native) and the libraries (build) to ensure cross-compilation works.

**Didactic check**: If you put `gcc` in `buildInputs`, it might work on simple setups, but it is technically incorrect because `gcc` is a tool you run, not a library you link. Always use `nativeBuildInputs` (or `packages`) for tools.

## Automation with `direnv`

Typing `nix develop` every time you open a terminal is tedious. We can automate this using `direnv`.

1. **Install direnv** (one-time global setup):

```bash
nix profile add nixpkgs#direnv

# You also need to hook direnv into your .bashrc/.zshrc
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
```

1. **Create `.envrc`**:

   In your project folder (where `flake.nix` is), run:

```bash
echo "use flake" > .envrc
```

1. **Allow**:

```bash
direnv allow
```

Now, whenever you `cd` into this directory, your shell automatically transforms into the Nix environment. When you `cd` out, it reverts to your system defaults.

## Inspecting the Environment

You can execute commands inside the environment without entering it interactively. This is useful for CI/CD pipelines.

```bash
# Run 'make' inside the nix environment
nix develop --command make

# Check environment variables
nix develop --command env | grep C_INCLUDE_PATH
```

## Summary

- **`nix develop`** replaces legacy `nix-shell` for Flakes.
- **`pkgs.mkShell`** is the function used to define these environments.
- **`nativeBuildInputs`** puts tools in your `$PATH`.
- **`buildInputs`** sets up library paths (headers/libs).
- **`direnv`** automates loading these environments when you change directories.

## Next Capsule

In the next capsule, we will examine the **Flake Architecture** in detail—understanding the `inputs`, `outputs`, and the critical `flake.lock` file that ensures reproducibility.

> **[Nix Capsules 12: Flake Architecture](./12-flake-architecture.md)**
