# Nix Capsules: Foundational Learning for Modern Nix (3.x)

**Nix Capsules** is a foundational learning resource for modern Nix. Its purpose is to build mental models that enable you to read and understand specialized documentation like the Home Manager manual, NixOS manual, and nix.dev reference.

This series teaches **modern Nix only** (flakes and unified CLI) through progressive capsules, building from basics to advanced patterns.

## Table of Contents

### Foundation (01-06)

1. [Why You Should Give it a Try](./pages/01-why-you-should-give-it-a-try.md)
2. [Install on Your Running System](./pages/02-install-on-your-running-system.md)
3. [Enter the Environment](./pages/03-enter-environment.md)
4. [The Nix Store](./pages/04-the-nix-store.md)
5. [Basics of Language](./pages/05-basics-of-language.md)
6. [Functions and Imports](./pages/06-functions-and-imports.md)

### Building (07-11)

7. [Our First Derivation](./pages/07-our-first-derivation.md)
8. [Store Path Mechanics](./pages/08-store-path-mechanics.md)
9. [Building with stdenv](./pages/09-building-with-stdenv.md)
10. [Automatic Runtime Dependencies](./pages/10-automatic-runtime-dependencies.md)
11. [Developing with nix develop](./pages/11-developing-with-nix-shell.md)

### Structure (12-14)

12. [Flake Architecture](./pages/12-flake-architecture.md)
13. [Package Composition](./pages/13-package-composition.md)
14. [Garbage Collector](./pages/14-garbage-collector.md)

### Advanced (15-18)

15. [Nixpkgs Deep Dive](./pages/15-nixpkgs-deep-dive.md)
16. [Advanced Overrides](./pages/16-advanced-overrides.md)
17. [Dependency Propagation](./pages/17-dependency-propagation.md)
18. [Store Internals](./pages/18-store-internals.md)

### Techniques (19-20)

19. [Multiple Outputs](./pages/19-multiple-outputs.md)
20. [Fetching Sources](./pages/20-fetching-sources.md)

## How to Use This Guide

Read sequentially from 01-20. Each capsule builds on previous concepts.

**After completing this series, you will be able to:**
- Read and understand nix.dev documentation independently
- Write your own flakes and derivations
- Use development environments with `nix develop`
- Understand store mechanics and garbage collection

## Resources

- [nix.dev](https://nix.dev/) - Command/language reference
- [Zero to Nix](https://zero-to-nix.com/) - Awareness and first exposure
- [NixOS Manual](https://nixos.org/manual/nixos/) - System configuration (after Nix Capsules)
- [Home Manager Manual](https://nix-community.github.io/home-manager/) - Home directory management (after Nix Capsules)
