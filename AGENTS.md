# AGENTS.md - Nix Capsules Project Guidelines

This file provides guidelines for AI agents working on the Nix Capsules educational project.

## Project Overview

**Capsules are the primary deliverables.** Nix Capsules is a foundational learning resource containing 20 progressive markdown capsules in `pages/` (01-20) teaching modern Nix (flakes + unified CLI) from basics to advanced patterns.

Infrastructure (flake.nix, validation scripts) exists only to support capsule quality. When editing, **prioritize capsule content over infrastructure**.

## Working on Capsules

### Core Principles (from MANIFEST.md)

1. **Self-Contained Requirement** - Each capsule MUST be complete and runnable without files from other capsules
2. **Copy-Paste Runnable** - All code examples MUST be syntactically complete and buildable (The "Hands-On" Rule)
3. **Fail-First Pedagogy** - Intentionally guide users into pitfalls to teach constraints
4. **Glass Box Approach** - Explain HOW things work, not just usage
5. **Modern Nix Only** - No legacy commands (`nix-env`, `nix-channel`, `nix-shell`)

### The Narrative Arc

Capsules must follow this progression strictly:

1. **Consumer (01-04)**: Using the Store, running binaries, paths and hashes
2. **Linguist (05-06)**: Syntax, Sets, Functions (Flake subset only)
3. **Builder (07-10)**: `derivation`, `stdenv`, Runtime Dependencies (Build vs Host separation)
4. **Developer (11)**: Ephemeral environments (`devShells`)
5. **Architect (12-13+)**: Project structure, Flakes, Composition, `callPackage`

### Capsule Structure

```markdown
# Nix Capsules N: Title

## Introduction
Brief context and what the reader will learn.

## Step 1: The Trap (Fail-First)
Show the wrong way first with expected error.
⚠️ Warning or Didactic Check

## Step 2: The Solution
Explain the correct approach with complete, runnable code.

### Complete Example
```nix
{
  description = "Full flake with all context";
  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; };
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system}.default = pkgs.hello;
    };
}
```

## Key Takeaways

- Bullet points summarizing concepts

```

### Code Examples Must:
- Include **full flake.nix** structure with `inputs` and `outputs`
- Use `nixos-unstable` as the nixpkgs reference
- Define `system` explicitly
- Have meaningful comments explaining **why**, not just what
- Be formatted with alejandra style

### Content Guidelines:
- Use `##` for main sections, `###` for subsections
- Use relative links: `[text](./XX-topic.md)`
- Update internal links if you rename or restructure referenced capsules
- Include Didactic Checks (mental quizzes) and Warnings (⚠️) for critical concepts
- **Never** use `import <nixpkgs>` (The Import Trap)
- **Never** use undefined placeholders like `# ...` or `src = ./.;` without content

## Development vs CI/CD Separation

### Local Development (ignored by .gitignore)
- `.direnv/` - Local Nix development environment
- `.direnv/flake-profile*` - Development profile symlinks
- `.envrc` - Direnv configuration
- `result` - Build artifacts
- `*.drv` - Nix derivation files

### CI/CD Infrastructure (kept in version control)
- `.github/workflows/` - GitHub Actions workflows
- `.github/scripts/` - Validation scripts (CI/CD dependencies)
- `.pre-commit-config.yaml` - Pre-commit hooks
- `flake.lock` - Dependency lock file

### Local Development Commands
```bash
# Enter Nix development shell (installs: statix, nil, alejandra)
nix develop

# Or use direnv (configured in .envrc)
direnv allow
```

### CI/CD Validation Commands
```bash
# Run GitHub Actions locally for testing (requires act tool)
act -j verify-commands

# Or use pre-commit hooks for local validation
pre-commit run --all-files
```

### Validation (run before committing capsule changes)

```bash
# Critical: Check for broken internal links after renames/restructuring
.github/scripts/check-links.sh pages

# Verify documented Nix commands exist
.github/scripts/check-commands.sh

# Check for deprecated command usage
.github/scripts/check-deprecated.sh pages

# Full validation suite
.github/scripts/check-links.sh pages && \
.github/scripts/check-commands.sh && \
.github/scripts/check-deprecated.sh pages && \
echo "All checks passed!"
```

### Linting & Formatting

```bash
# Lint Nix files
statix check .

# Format Nix files
alejandra .

# Lint shell scripts
shellcheck .github/scripts/*.sh

# Run pre-commit hooks
pre-commit run --all-files
```

## Code Style Guidelines

### Nix Code in Capsules

#### Formatting

- 2-space indentation
- Function arguments on separate lines for multi-parameter functions
- Run `alejandra .` before committing

#### Language Standards

- **Modern Nix Only**: `nix build`, `nix develop`, `nix run`
- **Prohibited**: `nix-env`, `nix-channel`, `nix-shell`
- **Allowed exceptions**: `nix-store` (graph inspection), `patchelf`, `direnv`

#### Dependency Attributes

- `nativeBuildInputs`: Tools that run on the build machine
- `buildInputs`: Libraries linked on the host machine
- `packages`: ONLY for `mkShell`, never for `mkDerivation`

### Shell Scripts (CI/CD infrastructure only)

- POSIX-compliant (`#!/bin/sh`)
- Use `set -e` for error handling
- Source utils.sh: `. "$(dirname "$0")/utils.sh"`
- Use logging: `log_info`, `log_success`, `log_error`, `log_warn`, `die`

## File Organization

```
.
├── pages/               # PRIMARY: Capsule markdown files (01-20)
│   ├── 01-why-you-should-give-it-a-try.md
│   └── ...
├── .github/            # CI/CD INFRASTRUCTURE (kept in version control)
│   ├── workflows/       # GitHub Actions workflows (essential for CI/CD)
│   └── scripts/        # Validation scripts (CI/CD dependencies)
├── flake.nix           # Dev shell (supporting)
├── MANIFEST.md         # Project philosophy
└── README.md           # Project overview
```

## Development vs CI/CD Separation

### Local Development (ignored by .gitignore)
- `.direnv/` - Local Nix development environment
- `.direnv/flake-profile*` - Development profile symlinks
- `.envrc` - Direnv configuration
- `result` - Build artifacts
- `*.drv` - Nix derivation files

### CI/CD Infrastructure (kept in version control)
- `.github/workflows/` - GitHub Actions workflows
- `.github/scripts/` - Validation scripts (CI/CD dependencies)
- `.pre-commit-config.yaml` - Pre-commit hooks
- `flake.lock` - Dependency lock file

### Local Development Commands
```bash
# Enter Nix development shell (installs: statix, nil, alejandra)
nix develop

# Or use direnv (configured in .envrc)
direnv allow
```

### CI/CD Validation Commands
```bash
# Run GitHub Actions locally for testing (requires act tool)
act -j verify-commands

# Or use pre-commit hooks for local validation
pre-commit run --all-files
```

### Validation (run before committing capsule changes)

```bash
# Critical: Check for broken internal links after renames/restructuring
.github/scripts/check-links.sh pages

# Verify documented Nix commands exist
.github/scripts/check-commands.sh

# Check for deprecated command usage
.github/scripts/check-deprecated.sh pages

# Full validation suite
.github/scripts/check-links.sh pages && \
.github/scripts/check-commands.sh && \
.github/scripts/check-deprecated.sh pages && \
echo "All checks passed!"
```

## Pre-Commit Checklist for Capsule Changes

1. ✅ All code examples are copy-paste runnable
2. ✅ No broken internal links (run check-links.sh)
3. ✅ No legacy commands used (`nix-env`, `nix-channel`, `nix-shell`)
4. ✅ Progressive complexity maintained (check narrative arc position)
5. ✅ Glass Box: explain how things work, not just usage
6. ✅ Fail-First: include intentional errors with explanations
7. ✅ Self-contained: no dependencies on files from other capsules

## Commit Messages

Format: `type: brief description`

- `capsule:` - Changes to capsule content
- `fix:` - Bug fixes
- `docs:` - Documentation updates
- `ci:` - CI/script changes
- `refactor:` - Code restructuring

Example: `capsule: clarify override vs overrideAttrs distinction in cap 16`

## Important Notes

- **Capsules > Infrastructure** - Focus on pedagogical quality over tooling
- **Self-Contained** - Each capsule must work independently
- **Runnable Code** - Examples must execute successfully (unless intentional failure)
- **Modern Nix** - All examples use flakes, no legacy patterns
- **Multi-arch Support** - Flakes should support: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin
- **Validate Links** - Always run `.github/scripts/check-links.sh` after structural changes
