# Progress Tracking: Nix Capsules Documentation Fix

## Overview

**Project**: Nix Capsules - Educational documentation for modern Nix (Nix 3.x)
**Location**: `/home/matt/Obsidian_Vaults/Matias/04-projects/prj-nix-capsules/`
**Status**: In Progress - Command Verification & Documentation Fixes

---

## What We Did

### 1. Analyzed and Updated AGENTS.md
- Created comprehensive documentation for agentic coding agents
- Documented modern vs legacy Nix commands with a 3-column table
- Added "Verifying Commands" section instructing agents to test commands in terminal before documenting
- Added "Garbage Collection Note" explaining why some legacy commands remain necessary

### 2. Discovered Critical Issue
- Found that **`nix store query`** does NOT exist in modern Nix CLI (contrary to original AGENTS.md)
- Verified this via terminal: `nix store query --help` returns "error: 'query' is not a recognised command"
- This was a significant documentation bug that would mislead readers

### 3. Verified All Commands in Documentation
- Extracted all `nix` commands from 20 markdown pages
- Ran terminal tests on each command to verify existence
- Created command verification table

### 4. Updated 5 Documentation Pages with Correct Commands

| Page | Issue Found | Fix Applied |
|------|-------------|-------------|
| `09-automatic-runtime-dependencies.md` | `nix store query --references` doesn't exist | Changed to `nix path-info --json <path> \| jq -r '.[].references[]'` |
| `11-garbage-collector.md` | Multiple non-existent `nix store gc` flags | Rewrote with correct modern commands |
| `17-nixpkgs-overriding-packages.md` | `nix store query --references` doesn't exist | Changed to `nix path-info --json` |
| `18-nix-store-paths.md` | `nix store list`, `nix store query` don't exist | Changed to `nix store ls`, `nix path-info` |
| `20-basic-dependencies-and-hooks.md` | `nix store query --references` doesn't exist | Changed to `nix path-info --json` |

### 5. Researched Garbage Collection Commands
- Discovered that `nix store gc` only supports `--max` and `--dry-run`
- Found no modern equivalent for generation management
- Verified `nix-collect-garbage` is still actively maintained and recommended
- Documented `nix profile wipe-history` as modern alternative for profile cleanup

---

## Key Findings: Modern vs Legacy Commands

| Legacy Command | Modern Equivalent | Notes |
|----------------|-------------------|-------|
| `nix-env -i pkg` | `nix profile add nixpkgs#pkg` | ✅ Works |
| `nix-env -u` | `nix profile upgrade` | ✅ Works |
| `nix-shell` | `nix develop` or `nix shell` | ✅ Works |
| `nix-build` | `nix build` | ✅ Works |
| `nix-instantiate` | `nix eval` | ✅ Works |
| `nix-store -q --references` | `nix path-info --json <path> \| jq -r '.[].references[]'` | No direct `nix store query` |
| `nix-store --gc` | `nix store gc` | Only `--max` and `--dry-run` work |
| `nix-store --gc --list-roots` | **No modern equivalent** | Legacy only |
| `nix-store --gc --delete-generations` | `nix-collect-garbage --delete-old` | No direct `nix store gc` equivalent |
| `nix-collect-garbage` | `nix-collect-garbage` (still recommended) | Wrapper command, not unified CLI |

---

## Files Modified

```
prj-nix-capsules/
├── AGENTS.md                          # Updated command table + GC notes
├── PROGRESS.md                        # This file
└── pages/
    ├── 09-automatic-runtime-dependencies.md
    ├── 11-garbage-collector.md        # Completely rewritten
    ├── 17-nixpkgs-overriding-packages.md
    ├── 18-nix-store-paths.md
    └── 20-basic-dependencies-and-hooks.md
```

---

## Key Decisions and Rationale

### 1. Keep `nix-collect-garbage` in documentation despite being "legacy"
- **Why**: The unified `nix` command does NOT provide equivalent functionality
- `nix store gc` only supports `--max` and `--dry-run`
- No modern replacement for `--list-roots`, `--delete-generations`, `--delete-dead`, `--empty-trash`
- `nix-collect-garbage` is actively maintained and recommended in official docs

### 2. Changed from `nix store query` to `nix path-info --json | jq`
- **Why**: `nix store query` does not exist in modern Nix
- `nix path-info --json` provides the same information in JSON format
- This is the correct modern approach

### 3. Added explicit "verify commands in terminal" instruction
- **Why**: Found multiple non-existent commands in documentation
- Prevents future documentation bugs
- Agents must run `--help` on commands before documenting them

---

## Commands Verified Working

| Command | Verified |
|---------|----------|
| `nix profile add nixpkgs#pkg` | ✅ |
| `nix profile upgrade` | ✅ |
| `nix develop` | ✅ |
| `nix build` | ✅ |
| `nix eval` | ✅ |
| `nix store gc` | ✅ (only `--max`, `--dry-run`) |
| `nix store delete` | ✅ |
| `nix path-info --json` | ✅ |
| `nix derivation show` | ✅ |
| `nix profile list` | ✅ |
| `nix profile history` | ✅ |
| `nix profile wipe-history` | ✅ |
| `nix-collect-garbage` | ✅ (still works, wrapper) |
| `nix store ls` | ✅ |
| `nix why-depends` | ✅ |

## Commands That Don't Exist (Never Document)

- `nix store query` (and any `--references`, `--graph`, `--tree`, `--size` variants)
- `nix store list`
- `nix store gc --list-roots`
- `nix store gc --delete-generations`
- `nix store gc --delete-dead`
- `nix store gc --empty-trash`

---

## Testing Protocol Used

When verifying a command, always:

```bash
# 1. Check if command exists
nix <command> --help

# 2. Test basic functionality (safe commands only)
nix <command> --dry-run

# 3. Check for available subcommands
nix <subcommand> --help

# 4. Compare with legacy if needed
nix-store --gc --help
```

---

## Remaining Work

### High Priority
1. **Review remaining pages** (01-08, 10, 12-16, 19) for similar issues
   - May contain non-verified `nix` commands
   - Search for patterns like `nix store query`, `nix store list`, `nix-collect-garbage -d`

2. **Verify all code examples in pages**
   - Some nix expressions may be outdated
   - Test with current Nix version (2.33.0)

### Medium Priority
3. **Add code examples to AGENTS.md for common patterns**
   - Show exact `jq` commands for parsing JSON output
   - Example: `nix path-info --json <path> | jq -r '.[].references[]'`

4. **Update AGENTS.md length**
   - Currently 193 lines (over 150 target, but within acceptable 150-300 range)
   - Could be trimmed if needed

### Lower Priority
5. **Consider adding a CI check**
   - Automate command verification in pull requests
   - Prevent regression of documented commands

---

## Pages to Review

| Page | Status |
|------|--------|
| `01-why-you-should-give-it-a-try.md` | ⏳ Pending |
| `02-install-on-your-running-system.md` | ⏳ Pending |
| `03-your-first-flake.md` | ⏳ Pending |
| `04-building-with-flakes.md` | ⏳ Pending |
| `05-packaging-software.md` | ⏳ Pending |
| `06-intro-to-nix-language.md` | ⏳ Pending |
| `07-intro-to-stdenv.md` | ⏳ Pending |
| `08-building-with-stdenv.md` | ⏳ Pending |
| `10-declarative-reproducible-environments.md` | ⏳ Pending |
| `12-how-nix-works.md` | ⏳ Pending |
| `13-building-packages.md` | ⏳ Pending |
| `14-override-design-pattern.md` | ⏳ Pending |
| `15-pinning-nixpkgs.md` | ⏳ Pending |
| `16-breaking-down-the-stdenv-build-phases.md` | ⏳ Pending |
| `19-deploying-nixos-systems.md` | ⏳ Pending |

---

## Last Updated

January 18, 2026

## Session Context

- **Phase**: Verifying and fixing documentation commands
- **Last action**: Updated AGENTS.md with comprehensive command table and GC notes
- **Next step**: Review remaining pages (01-08, 10, 12-16, 19) for similar issues
