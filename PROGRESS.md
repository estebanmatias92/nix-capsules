# Progress Tracking: Nix Capsules Documentation Project

## Overview

**Project**: Nix Capsules - Foundational learning resource for modern Nix (3.x)
**Location**: `/home/matt/Obsidian_Vaults/Matias/04-projects/prj-nix-capsules/`
**Status**: Complete Refactoring - 20 capsules restructured for optimal learning flow

---

## Completed Refactoring Summary

### Mission Clarity (AGENTS.md Updated)

- Defined Nix Capsules as **foundational learning resource** for building mental models
- Positioned against ecosystem: Zero to Nix (awareness), nix.dev (reference), NixOS/Home Manager manuals (specialized)
- Scope: User-level Nix only (flakes, packages, dev environments) - no NixOS, no Home Manager

### Complete Capsule Restructuring (20 capsules)

| Phase | # | Title | Key Changes |
|-------|---|-------|-------------|
| **Foundation** | 01 | Why You Should Give it a Try | Original |
| | 02 | Install on Your Running System | Original |
| | 03 | Enter the Environment | Original |
| | 04 | **The Nix Store** | NEW - Store concept before language |
| | 05 | Basics of Language | Renamed from 04-basics-of-language |
| | 06 | Functions and Imports | Renamed |
| **Building** | 07 | Our First Derivation | Renamed |
| | 08 | **Store Path Mechanics** | NEW - Hashing, NAR, content-addressing |
| | 09 | **Building with stdenv** | NEW - Consolidated (was 3 capsules) |
| | 10 | Automatic Runtime Dependencies | Renamed |
| | 11 | Developing with nix develop | Renamed |
| **Structure** | 12 | **Flake Architecture** | NEW - Dedicated flake coverage |
| | 13 | **Package Composition** | NEW - Merged inputs+callPackage |
| | 14 | Garbage Collector | Renumbered from 11 |
| **Advanced** | 15 | **Nixpkgs Deep Dive** | NEW - Merged params+overrides |
| | 16 | **Advanced Overrides** | NEW - makeOverridable, chaining |
| | 17 | **Dependency Propagation** | NEW - buildInputs, hooks |
| | 18 | **Store Internals** | NEW - FODs, CAD, path resolution |
| **Techniques** | 19 | **Multiple Outputs** | NEW |
| | 20 | **Fetching Sources** | NEW |

### Deleted Redundant Files

- `08-generic-builders.md` (merged into 09)
- `15-nix-search-paths.md` (out of scope)
- `19-fundamentals-of-stdenv.md` (merged into 09)
- `12-inputs-design-pattern.md` (merged into 13)
- `13-callpackage-design-pattern.md` (merged into 13)
- `14-override-design-pattern.md` (merged into 16)
- `16-nixpkgs-parameters.md` (merged into 15)
- `17-nixpkgs-overriding-packages.md` (merged into 15)
- `18-nix-store-paths.md` (content moved to 08)
- `20-basic-dependencies-and-hooks.md` (merged into 17)
- `07-working-derivation.md` (duplicate, removed)

### Files Created

- `04-the-nix-store.md` - Store mechanics fundamentals
- `08-store-path-mechanics.md` - Hashing, NAR, base32 encoding
- `09-building-with-stdenv.md` - Single consolidated stdenv coverage
- `12-flake-architecture.md` - Complete flake reference
- `13-package-composition.md` - Inputs pattern + callPackage
- `15-nixpkgs-deep-dive.md` - Overlays, config, parameters
- `16-advanced-overrides.md` - makeOverridable, fixed-point
- `17-dependency-propagation.md` - buildInputs, nativeBuildInputs, hooks
- `18-store-internals.md` - FODs, content-addressing, path resolution
- `19-multiple-outputs.md` - env syntax, output splitting
- `20-fetching-sources.md` - fetchurl, fetchFromGitHub, hash verification

---

## Key Structural Changes

### Before vs After

| Aspect | Before | After |
|--------|--------|-------|
| Store paths | Capsule 18 (after derivations) | Capsule 04 + 08 (before derivations) |
| stdenv coverage | 3 capsules (08, 19, 20) | 1 capsule (09) |
| Flakes | Mentioned in capsule 05 only | Dedicated capsule 12 |
| NIX_PATH | Capsule 15 | Removed (out of scope) |
| Total capsules | 20 (with redundancy) | 20 (no redundancy) |
| CI/CD | Mentioned | Removed (out of scope) |

### New Pedagogical Flow

1. **Foundation** (01-06): Why → Install → Use → Store → Language → Functions
2. **Building** (07-11): Derivation → Store mechanics → stdenv → Runtime deps → Dev environments
3. **Structure** (12-14): Flakes → Package composition → Garbage collection
4. **Advanced** (15-18): Nixpkgs → Overrides → Dependencies → Store internals
5. **Techniques** (19-20): Multiple outputs → Fetching sources

---

## Updated AGENTS.md

### Mission Statement Added

```
**Nix Capsules** is a **foundational learning resource** for modern Nix (3.x).
Its purpose is to build mental models that enable users to read and understand
specialized documentation like the Home Manager manual, NixOS manual, and
nix.dev reference.
```

### Resource Ecosystem Table

| Resource | Purpose | When to Use |
|----------|---------|-------------|
| Zero to Nix | Awareness/teaser | First exposure, "a-ha moments" |
| nix.dev | Command/language reference | Look up syntax, options, builtins |
| Nix Capsules | Foundational mental models | Learn how Nix works conceptually |

### Scope Defined

- **In**: Package management with flakes, dev environments, derivations, patterns, store mechanics
- **Out**: NixOS system config, Home Manager, CI/CD deployment patterns

---

## Best Practices Updated

1. **Modern Nix First**: Teach flakes and unified CLI as the only way
2. **Progressive Disclosure**: Start simple, add complexity gradually
3. **Verify Code Examples**: Test all Nix code snippets before committing
4. **Consistent Terminology**: Use same terms throughout
5. **Concept Transferability**: Focus on mental models (store, derivations, overlays)

---

## Commands Verified Working

| Command | Status |
|---------|--------|
| `nix profile add nixpkgs#pkg` | ✅ |
| `nix profile upgrade` | ✅ |
| `nix develop` | ✅ |
| `nix build` | ✅ |
| `nix eval` | ✅ |
| `nix store gc` | ✅ (only `--max`, `--dry-run`) |
| `nix path-info --json` | ✅ |
| `nix derivation show` | ✅ |
| `nix profile list` | ✅ |
| `nix profile wipe-history` | ✅ |
| `nix-collect-garbage` | ✅ (wrapper, still recommended) |

---

## Commands That Don't Exist

- `nix store query` (and variants)
- `nix store list`
- `nix store gc --list-roots`
- `nix store gc --delete-generations`

---

## Last Updated

January 20, 2026

---

## What We Did

1. Created `.gitignore` with OS files, editor directories, and Nix build artifacts excluded
2. Fixed typos in capsule 02's "Next Capsule" section
3. Committed refactored changes (30 files changed, restructured capsules)
4. Updated README.md with new table of contents
5. Fixed capsule 14 intro to correctly reference capsule 13
6. Refactored "Next Capsule" sections in capsules 03-19 to use blockquote links

---

## Pending Tasks

1. Verify all code examples in new capsules
2. Consider adding CI check for command verification
