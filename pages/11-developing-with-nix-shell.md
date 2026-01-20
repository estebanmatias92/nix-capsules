# Nix Capsules 11: Developing with nix develop

## Introduction

Welcome to the tenth Nix capsule. In the previous capsule, we explored automatic runtime dependencies. Now we'll use `nix develop` to create **isolated development environments**—shells where you have exactly the dependencies you need for a project, without installing them globally.

## What is nix develop?

The `nix develop` command enters a shell environment with all build dependencies available. It's the modern replacement for `nix-shell` and provides a cleaner, more powerful interface.

```bash
# Enter development shell for a package
nix develop .#myapp

# Run a command in the development environment
nix develop .#myapp --command make test
```

## Flake-based Development Shells

With flakes, development shells are defined in `flake.nix`:

```nix
{
  description = "My project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      buildInputs = [
        nixpkgs.legacyPackages.x86_64-linux.gcc
        nixpkgs.legacyPackages.x86_64-linux.make
        nixpkgs.legacyPackages.x86_64-linux.pkg-config
      ];

      # Set environment variables
      MY_VAR = "hello";

      # Run commands on shell entry
      shellHook = ''
        echo "Welcome to the development shell!"
        export PS1="[dev] \u@\h \w $ "
      '';
    };
  };
}
```

## Entering the Development Shell

```bash
# Default shell for the flake
nix develop

# Specific package's development shell
nix develop .#myapp

# With custom packages (adhoc shell)
nix develop -c bash
nix develop -e nixpkgs#gcc -e nixpkgs#cmake
```

## Environment Variables

All `buildInputs` are automatically added to `PATH`, and custom variables are set:

```bash
nix develop .#myapp
echo $CC          # gcc
echo $CXX         # g++
echo $NIX_BUILD_CORES  # Number of parallel build jobs
```

Access them in your shell scripts and build commands.

## The shellHook

Run commands when entering the shell:

```nix
mkShell {
  buildInputs = [ pkgs.git ];

  shellHook = ''
    # Set up git completion
    source ~/.git-completion.bash

    # Print useful info
    echo "Build with: make"
    echo "Test with: make test"
  '';
}
```

## Running Commands

Execute commands within the development environment:

```bash
# Run a single command
nix develop .#myapp --command make

# Or chain commands
nix develop .#myapp --command 'make && ./configure'
```

## Caching with direnv

For IDE-like integration, use `direnv` with `nix develop`:

```bash
# Install direnv and nix-direnv
nix profile install nixpkgs#direnv
nix profile install nixpkgs#nix-direnv

# In your project, create .envrc
echo "use flake" > .envrc

# Allow direnv
direnv allow
```

Now your shell automatically enters the Nix environment when you `cd` into the project.

## Comparing with Traditional Approaches

| Approach        | Dependencies    | Isolation | Reproducibility |
| --------------- | --------------- | --------- | --------------- |
| System packages | Global          | None      | Low             |
| Docker          | Container-level | High      | Medium          |
| nix develop     | Per-project     | High      | High            |

`nix develop` provides system-level isolation without container overhead.

## Multi-language Support

Define environments for different languages:

```nix
{
  outputs = { self, nixpkgs }: {
    devShells.x86_64-linux = {
      default = self.devShells.x86_64-linux.python;
      python = nixpkgs.legacyPackages.x86_64-linux.mkShell {
        buildInputs = [
          nixpkgs.legacyPackages.x86_64-linux.python311
          nixpkgs.legacyPackages.x86_64-linux.poetry
        ];
      };
      rust = nixpkgs.legacyPackages.x86_64-linux.mkShell {
        buildInputs = with nixpkgs.legacyPackages.x86_64-linux; [
          rustc
          cargo
          rust-analyzer
        ];
      };
    };
  };
}
```

## Environment Inspection

Check what an environment provides:

```bash
# Show available tools
nix develop .#myapp --command which -a gcc make cmake

# Print all environment variables
nix develop .#myapp --command env | grep -E '^(PATH|CC|CXX)'

# See the derivation being used
nix eval .#devShells.x86_64-linux.default
```

## Integration with IDEs

Configure your IDE to use the Nix environment:

**VS Code**: Use the Nix environment service extension or set `nix.server` in settings.

**Neovim**: Use `null-ls` or `ale` with nix lsp servers.

**CLion/PyCharm**: Set toolchain to use `nix develop` environment.

## Summary

- `nix develop` creates isolated development shells from flake definitions
- `mkShell` defines environments with buildInputs and shellHooks
- The environment provides exact dependencies without global installation
- `direnv` integrates nix environments with shell navigation
- Works with any language—C, Rust, Python, Haskell, and more

## Next Capsule

In the next capsule, we'll explore the **flake architecture**—how the flake system works.

> [**Nix Capsules 12: Flake Architecture**](./12-flake-architecture.md)
