# Nix Capsules 12: Flake Architecture

## Introduction

In the previous capsule, we covered garbage collection. Now we'll explore **flakes**—the modern standard for organizing Nix projects with a consistent, reproducible structure.

Flakes provide a standardized way to:

- Declare dependencies (inputs)
- Expose outputs (packages, dev shells, etc.)
- Lock versions for reproducibility

## What is a Flake?

A flake is a Nix file (typically `flake.nix`) with two attributes:

```nix
{
  inputs = { ... };  # Dependencies
  outputs = { ... }; # What the flake provides
}
```

### Flake Requirements

1. Must be in a directory with a `flake.nix` file
2. The file must evaluate to an attribute set with `inputs` and `outputs`
3. Inputs must be valid flake references
4. Outputs must be functions of inputs

### Minimal Flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
  };
}
```

This flake:

- Depends on nixpkgs from GitHub
- Exposes one package: `hello` for x86_64-linux

## The inputs Attribute

`inputs` declares dependencies:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  flake-utils.url = "github:numtide/flake-utils";

  rust-overlay.url = "github:oxalica/rust-overlay";
};
```

### Input Types

| Type | Example | When to Use |
| ---- | ------- | ----------- |
| GitHub | `github:NixOS/nixpkgs/nixos-unstable` | Standard packages |
| Git | `git+https://example.com/repo?ref=main&rev=abc123` | Custom repositories |
| Path | `path:/path/to/local/flake` | Local development |
| Flake | `flake:nixpkgs` | From flake registry |
| Tarball | `github:NixOS/nixpkgs/archive.tar.gz` | Download directly |

### Input Attributes

```nix
inputs = {
  # Branch reference
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  # Specific commit
  nixpkgs.url = "github:NixOS/nixpkgs?rev=abc123def456...";

  # With inputs for the flake itself
  rust-overlay.inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
};
```

## The outputs Attribute

`outputs` is a function that receives inputs and returns what the flake provides:

```nix
outputs = { self, nixpkgs, flake-utils }: {
  # Package output
  packages.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.hello;

  # Development shell
  devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
    buildInputs = [ nixpkgs.legacyPackages.x86_64-linux.hello ];
  };
};
```

### Standard Output Types

| Output Type | Purpose | Key Attributes |
| ----------- | ------- | -------------- |
| `packages` | Buildable packages | System-specific keys |
| `devShells` | Development environments | `default` for default shell |
| `apps` | Runnable applications | `type = "app"`, `program` |
| `overlays` | Nixpkgs overlays | Applied to nixpkgs |
| `nixosModules` | NixOS configuration | Module functions |
| `homeModules` | Home Manager modules | Module functions |
| `formatter` | Code formatter | `packages.*.formatter` |

### Complete Example

```nix
{
  description = "My Nix project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.myapp = pkgs.callPackage ./myapp.nix { };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            rustc
            cargo
            rust-analyzer
          ];
        };
      }
    );
}
```

## The flake.lock File

When you first evaluate a flake, Nix creates `flake.lock`:

```json
{
  "version": 7,
  "nodes": {
    "nixpkgs": {
      "type": "github",
      "owner": "NixOS",
      "repo": "nixpkgs",
      "rev": "abc123...",
      "narHash": "sha256-...",
      "locked": {
        "lastModified": 1700000000,
        "narHash": "sha256-...",
        "owner": "NixOS",
        "repo": "nixpkgs",
        "rev": "abc123...",
        "type": "github"
      },
      "original": {
        "owner": "NixOS",
        "repo": "nixpkgs",
        "rev": "nixos-unstable",
        "type": "github"
      }
    }
  },
  "root": "nixpkgs"
}
```

### Why lock Files Matter

1. **Reproducibility**: Same inputs always produce same outputs
2. **Security**: Pin to known-good commits
3. **Caching**: Faster evaluations (no network lookups)
4. **Auditability**: Know exactly what versions were used

### Updating lock Files

```bash
# Update all inputs to latest
nix flake update

# Update specific input
nix flake update nixpkgs

# Update to specific revision
nix flake lock --override-input nixpkgs github:NixOS/nixpkgs/23.11
```

## Using Flakes

### Building Packages

```bash
# Build default package
nix build

# Build specific package
nix build .#myapp

# Build for specific system
nix build .#myapp.x86_64-darwin
```

### Development Shells

```bash
# Enter default development shell
nix develop

# Enter specific shell
nix develop .#myshell

# Run command in shell
nix develop .#myshell --command make test
```

### Running Apps

```bash
# Run default app
nix run

# Run specific app
nix run .#myapp
```

## Flake References

Flakes can reference other flakes:

```bash
# From command line
nix run github:NixOS/nixpkgs#hello

nix develop github:owner/repo#devshell

# In flake.nix
inputs = {
  myflake.url = "github:owner/repo";
};

outputs = { self, myflake }: {
  packages.default = myflake.packages.default;
};
```

### Flake Registry

The flake registry maps names to URLs:

```bash
# List registry
nix registry list

# Add custom entry
nix registry add nixpkgs github:NixOS/nixpkgs/nixos-unstable

# Remove entry
nix registry remove nixpkgs
```

## Templates

Start projects from templates:

```bash
# List templates
nix flake templates

# Use template
nix flake init --template github:owner/repo#template-name
```

### Common Templates

```bash
# Simple template
nix flake init

# With dev shell
nix flake init --template github:numtide/flake-templates#devshells
```

## Best Practices

### 1. Always Include Description

```nix
{
  description = "My application with useful description";

  inputs = { ... };
  outputs = { ... };
}
```

### 2. Use Specific Revisions for Production

```nix
inputs = {
  # Good for production
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

  # Or for unstable with lock file
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
};
```

### 3. Pin Critical Dependencies

```nix
inputs = {
  # Pin to specific revision for reproducibility
  mylib.url = "github:owner/mylib?rev=abc123def456...";
};
```

### 4. Use flake-utils for Multi-System

```nix
outputs = { self, nixpkgs, flake-utils }:
  flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.default = pkgs.hello;
    }
  );
```

### 5. Commit Both Files

```bash
git add flake.nix flake.lock
git commit -m "Add flake.nix with locked dependencies"
```

## Common Patterns

### Pattern 1: Simple Package

```nix
{
  description = "My package";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.default =
      nixpkgs.legacyPackages.x86_64-linux.hello;
  };
}
```

### Pattern 2: Development Environment

```nix
{
  description = "My dev environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: {
    devShells.x86_64-linux.default =
      nixpkgs.legacyPackages.x86_64-linux.mkShell {
        buildInputs = [
          nixpkgs.legacyPackages.x86_64-linux.gcc
          nixpkgs.legacyPackages.x86_64-linux.make
        ];
      };
  };
}
```

### Pattern 3: Multiple Packages

```nix
{
  description = "My packages";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      packages.x86_64-linux.package-a = pkgs.hello;
      packages.x86_64-linux.package-b = pkgs.figlet;
    };
}
```

### Pattern 4: With Overlays

```nix
{
  description = "Project with overlay";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  my-overlay.url = "github:owner/my-overlay";

  outputs = { self, nixpkgs, my-overlay }: {
    overlays.default = my-overlay.default;

    packages.x86_64-linux.default =
      (import nixpkgs {
        system = "x86_64-linux";
        overlays = [ my-overlay.default ];
      }).mypackage;
  };
}
```

## Troubleshooting

### "flake is not allowed"

Flakes aren't enabled. Add to `~/.config/nix/nix.conf`:

```ini
experimental-features = nix-command flakes
```

### "input has inconsistent version"

The lock file is out of sync:

```bash
nix flake update
```

### "cannot evaluate flake"

There's an error in your `flake.nix`. Check syntax:

```bash
nix eval --file flake.nix
```

## Summary

- Flakes provide a standardized project structure
- `inputs` declare dependencies, `outputs` expose results
- `flake.lock` ensures reproducibility
- Use `nix build`, `nix develop`, `nix run` with flakes
- Standard output types: packages, devShells, apps, overlays
- Pin dependencies for production, use lock file for CI

## Next Capsule

In the next capsule, we'll explore **package composition patterns**—how to organize multiple packages and their dependencies efficiently.

```nix
# Next: ./13-package-composition.md
```
