# AGENTS.md - Nix Capsules Documentation Project

## Mission Statement

**Nix Capsules** is a **foundational learning resource** for modern Nix (3.x). Its purpose is to build mental models that enable users to read and understand specialized documentation like the Home Manager manual, NixOS manual, and nix.dev reference.

### What Nix Capsules Is

- **Coherent, sequential education**: 20+ progressive capsules building from basics to advanced patterns
- **Modern Nix only**: Flakes and unified CLI as the defacto standard
- **Concept-focused**: Teaches transferable understanding (store mechanics, derivations, overlays)
- **Preparatory**: Users who complete the series can read ecosystem documentation independently

### What Other Resources Are For

| Resource | Purpose | When to Use |
|----------|---------|-------------|
| **Zero to Nix** | Awareness/teaser for Nix | First exposure, "a-ha moments" |
| **nix.dev** | Command/language reference | Look up syntax, options, builtins |
| **NixOS Manual** | System configuration reference | Configure NixOS systems |
| **Home Manager Manual** | Home directory management | Manage ~/.config with Nix |
| **Nix Capsules** | Foundational mental models | Learn how Nix works conceptually |

### Scope

Nix Capsules covers **user-level Nix**:
- Package management with flakes
- Development environments (`nix develop`)
- Building packages and derivations
- Common patterns (overrides, inputs, callPackage)
- Nix store mechanics and garbage collection

**Out of scope** (covered by dedicated manuals):
- Full NixOS system configuration (NixOS Manual)
- Home directory management (Home Manager Manual)
- CI/CD deployment patterns (nix.dev, FlakeHub docs)

### Modern Nix Standard

This documentation teaches **modern Nix only** (Nix 3.x with flakes enabled):

- **Flakes**: Use `flake.nix` for project-level dependency management
- **Unified CLI**: Use `nix` command (not legacy `nix-env`, `nix-instantiate`, etc.)
- **Experimental features**: `nix-command` and `flakes` enabled

### Modern vs Legacy Command Reference

| Legacy Command                        | Modern Command / Equivalent                                      | Notes                                     |
| ------------------------------------- | ---------------------------------------------------------------- | ----------------------------------------- |
| `nix-env -i pkg`                      | `nix profile add nixpkgs#pkg`                                    | Use unified CLI                           |
| `nix-env -u`                          | `nix profile upgrade`                                            | Use unified CLI                           |
| `nix-shell`                           | `nix develop` or `nix shell`                                     | Use unified CLI                           |
| `nix-build`                           | `nix build`                                                      | Use unified CLI                           |
| `nix-instantiate`                     | `nix eval`                                                       | Use unified CLI                           |
| `nix-store -q --references`           | `nix path-info --json --json-format 1 <path> \| jq -r '.[].references[]'`        | No direct `nix store query`               |
| `nix-store --gc`                      | `nix store gc`                                                   | Basic GC only                             |
| `nix-store --gc --list-roots`         | (no direct modern equivalent)                                    | Legacy only                               |
| `nix-store --gc --delete-generations` | `nix-collect-garbage --delete-old` or `nix profile wipe-history` | Use wrapper command                       |
| `nix-collect-garbage`                 | `nix-collect-garbage` (still recommended)                        | No modern equivalent, still actively used |

### Garbage Collection Note

The unified `nix` command provides only basic GC via `nix store gc`. For comprehensive cleanup including profile generations:

- **Basic GC**: `nix store gc`
- **Profile management**: `nix profile wipe-history --older-than Nd`
- **Full cleanup**: `nix-collect-garbage --delete-old` (recommended, no modern equivalent)

The `nix-collect-garbage` command is actively maintained and recommended in official documentation despite not being part of the unified `nix` CLI structure.

### Flake-first Approach

```nix
{
  description = "My Nix project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.hello;

    devShells.x86_64-linux.default = nixpkgs.mkShell {
      buildInputs = [ nixpkgs.legacyPackages.x86_64-linux.hello ];
    };
  };
}
```

## Project Structure

```
prj-nix-capsules/
├── index.md              # Main landing page with table of contents
├── PROGRESS.md           # Track current work status and pending tasks
├── pages/                # Documentation pages (numbered sequentially)
│   ├── 01-why-you-should-give-it-a-try.md
│   ├── 02-install-on-your-running-system.md
│   └── ...
└── AGENTS.md             # This file
```

### Before Starting Work

**Read `PROGRESS.md` first** to understand the current state of the project:

- What phases have been completed
- Which pages have been modified and their status
- What pending work exists
- Key decisions and rationale made during the project

### After Making Changes

**Update `PROGRESS.md`** to keep the project state current:

- Add new work to "What We Did" section
- Update file lists (committed vs pending)
- Add new key decisions and rationale
- Update page status table
- Update session context and next steps

## Verification Commands

Verify Nix code examples:

```bash
nix repl
```

Then type expressions to confirm expected output. Use `nix path-info --json <path>` for store path information.

### Verifying Commands

Before adding or updating commands in this documentation:

1. **Run with `--help` to verify the command exists**:

   ```bash
   nix profile add --help
   ```

2. **Check for typos or deprecated flags** - commands may exist but have different flags

3. **Test the actual command** if possible to confirm it works as expected

4. **If a command doesn't exist**, mark it as "(no direct modern equivalent)" rather than inventing a command

**Example of what NOT to do:**

- Do NOT write `nix store query --references` - this command does NOT exist
- Instead: mark it as `(no direct modern equivalent)`

**Example of what TO do:**

- Run `nix store --help` to see all available subcommands
- Run `nix store gc --help` to verify a specific command works
- If uncertain, test the command before documenting it

## Code Style Guidelines

### Markdown Formatting

- Use standard Markdown syntax throughout
- Code blocks must specify language (`nix,`bash)
- Use ATX-style headers (`#` for h1, `##` for h2, etc.)

### Nix Code Examples

- Proper indentation (2 spaces per level)
- Brief comments for complex concepts
- Show expected output for REPL commands
- Use `nix-repl>` prefix for interactive examples

```nix
nix-repl> 1 + 2
3
```

### Imports

```nix
import ./default.nix                    # Local file
fetchurl { url = "https://..."; sha256 = "..."; }
fetchFromGitHub { owner = "Owner"; repo = "Repo"; rev = "..."; sha256 = "..."; }
builtins.attrNames { a = 1; b = 2; }    # => ["a" "b"]
```

### Types

```nix
"hello"                                # string
42                                     # int
3.14                                   # float
[1 2 3]                                # list
{ key = "value"; }                     # attrset
true                                   # bool
null                                   # null
```

### Error Handling

```nix
throw "error message"                  # Abort evaluation
assert condition: expr                 # Fail if false
builtins.tryEval expr                  # Safe eval: { success = true/false; value = ...; }
```

### Content Organization

- Each page follows `XX-topic-name.md` naming (2-digit prefix)
- Pages numbered sequentially following Table of Contents order
- Each page starts with `# Nix Capsules N: Topic Title`
- Include a "## Summary" section at the end
- Include a "## Next Capsule" section linking to the following page

### Links and References

- Use relative links: `./pages/XX-topic.md`
- Link to external Nix documentation when appropriate
- Avoid broken links; verify internal references exist

### Naming Conventions

- Filenames: kebab-case with 2-digit prefix (e.g., `14-override-design-pattern.md`)
- Header titles: Title Case (e.g., "Override Design Pattern")
- Code variables: lowercase with dashes (Nix convention)
- Nix attribute sets: camelCase keys

## Related Resources

Use these resources as references for Nix concepts and commands. Each serves a different purpose in the learning journey.

### Zero to Nix (Awareness/Teaser)

**Main Site**: https://zero-to-nix.com/

Best for: First exposure to Nix, "a-ha moments"

This is a **marketing resource** from Determinate Systems that gives newcomers a quick taste of what Nix can do. It intentionally stays surface-level and links to nix.dev for practical usage.

**Quick Start Guide** (8 steps):
- [Install Nix](https://zero-to-nix.com/start/install)
- [Run a program](https://zero-to-nix.com/start/nix-run)
- [Development environments](https://zero-to-nix.com/start/nix-develop)
- [Build a package](https://zero-to-nix.com/start/nix-build)
- [Search packages](https://zero-to-nix.com/start/nix-search)
- [Turn project into flake](https://zero-to-nix.com/start/init-flake)
- [Uninstall](https://zero-to-nix.com/start/uninstall)
- [Learn more](https://zero-to-nix.com/start/learn-more)

**Core Concepts** (concise explanations):
- [Nix](https://zero-to-nix.com/concepts/nix/)
- [Nix flakes](https://zero-to-nix.com/concepts/flakes/)
- [Derivations](https://zero-to-nix.com/concepts/derivations/)
- [The Nix store](https://zero-to-nix.com/concepts/nix-store/)
- [Development environments](https://zero-to-nix.com/concepts/dev-env/)
- [Closures](https://zero-to-nix.com/concepts/closures/)
- [Incremental builds](https://zero-to-nix.com/concepts/incremental-builds/)

### nix.dev (Reference Manual)

**Quick Start**: https://nix.dev/manual/nix/2.26/quick-start
**Derivations**: https://nix.dev/manual/nix/2.28/language/derivations

Best for: Looking up command syntax, language builtins, options

This is the **official reference documentation** for the Nix language and commands. Use it to:
- Look up specific command flags
- Reference builtin functions
- Check language syntax rules

**Command Reference** (unified CLI - experimental but recommended):
- https://nix.dev/manual/nix/2.26/command-ref/new-cli/nix
- https://nix.dev/manual/nix/2.26/command-ref/new-cli/nix3-build
- https://nix.dev/manual/nix/2.26/command-ref/new-cli/nix3-develop
- https://nix.dev/manual/nix/2.26/command-ref/new-cli/nix3-flake
- https://nix.dev/manual/nix/2.26/command-ref/new-cli/nix3-profile
- https://nix.dev/manual/nix/2.26/command-ref/new-cli/nix3-store
- https://nix.dev/manual/nix/2.26/command-ref/new-cli/nix3-derivation
- https://nix.dev/manual/nix/2.26/command-ref/new-cli/nix3-eval
- https://nix.dev/manual/nix/2.26/command-ref/new-cli/nix3-run
- https://nix.dev/manual/nix/2.26/command-ref/new-cli/nix3-repl

**Language Reference**:
- https://nix.dev/manual/nix/2.26/language/
- https://nix.dev/manual/nix/2.26/language/types
- https://nix.dev/manual/nix/2.26/language/syntax
- https://nix.dev/manual/nix/2.26/language/builtins

**Package Management**:
- https://nix.dev/manual/nix/2.26/package-management/profiles
- https://nix.dev/manual/nix/2.26/package-management/garbage-collection

### NixOS and Flakes Book

**GitHub**: https://github.com/ryan4yin/nixos-and-flakes-book

Best for: Deeper practical examples, NixOS configuration

A comprehensive book covering both user-level Nix and full system configuration with NixOS.

### Nix Pills (Historical)

**Main**: https://nixos.org/guides/nix-pills/

Best for: Understanding historical context, original derivation examples

The classic Nix tutorial series. Some content is outdated (pre-flakes) but still valuable for understanding the underlying mechanics. Verify examples against modern Nix.

### External References

- [nix.dev tutorials - Declarative developer environments](https://nix.dev/tutorials/declarative-and-reproducible-developer-environments)
- [nix.dev tutorials - Dev environment](https://nix.dev/tutorials/dev-environment)
- [Ian Henry's blog - How to learn Nix](https://ianthehenry.com/posts/how-to-learn-nix/)
- [Shopify Engineering - What is Nix?](https://shopify.engineering/what-is-nix)
- [Nix Pills - Our first derivation](https://nixos.org/guides/nix-pills/our-first-derivation)

## Software Engineering Practices

This project follows software engineering best practices to ensure maintainability, readability, and reliability.

### Core Principles

| Practice | Application to This Project |
|----------|----------------------------|
| **Modularity** | CI scripts are split into dedicated files under `.github/scripts/` |
| **DRY (Don't Repeat Yourself)** | Shared logic extracted to `utils.sh`; repeated patterns use functions |
| **Single Responsibility** | Each script does one thing (check links / verify commands / check deprecations) |
| **Separation of Concerns** | Workflows orchestrate; scripts execute; config defines parameters |
| **KISS (Keep It Simple, Stupid)** | Avoid over-engineering; prefer clear, simple solutions |

### Architecture

```
.github/
├── workflows/
│   └── verify-commands.yml    # Orchestration only
├── scripts/
│   ├── check-links.sh         # Validates internal links
│   ├── check-commands.sh      # Verifies nix commands exist
│   ├── check-deprecated.sh    # Flags legacy command usage
│   ├── check-nix-hash.sh      # Tests nix-hash command
│   └── utils.sh               # Shared functions (POSIX-compliant)
└── .pre-commit-config.yaml    # Pre-commit hooks configuration
```

### Script Guidelines

All scripts in `.github/scripts/` must follow these rules:

1. **POSIX-compliant**: Use `/bin/sh` (not bash-specific features)
2. **Shellcheck pass**: Run `shellcheck` before committing
3. **Exit codes**: Return 0 on success, non-zero on failure
4. **Error handling**: Use `set -e` for fail-fast behavior
5. **Logging**: Use `log_info`, `log_success`, `log_error`, `log_warn` from `utils.sh`
6. **No hardcoded paths**: Use `$(dirname "$0")` for script-relative paths

### Pre-commit Hooks

The project uses pre-commit for local validation:

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Run manually
pre-commit run --all-files
```

**Available hooks:**
- `check-links`: Validates internal markdown links
- `shellcheck`: Lints all shell scripts

### Version Control

- **Conventional Commits**: Use `feat:`, `fix:`, `docs:`, `chore:` prefixes
- **Small, Focused PRs**: One logical change per PR
- **Branch Protection**: Require PR reviews before merging to main

### Code Quality

- **Shell scripts**: Pass `shellcheck` validation
- **Error messages**: Clear, actionable, and consistent
- **Comments**: Explain "why", not "what"

1. **Modern Nix First**: Teach flakes and unified CLI as the only way. Legacy commands are documented only when necessary (e.g., `nix-collect-garbage`).
2. **Progressive Disclosure**: Start simple, add complexity gradually
3. **Verify Code Examples**: Test all Nix code snippets before committing
4. **Consistent Terminology**: Use same terms throughout
5. **Concept Transferability**: Focus on mental models that apply across all Nix usage (store mechanics, derivation evaluation, overlay composition)

## Documentation Best Practices

1. **Modern Nix First**: Teach flakes and unified CLI as the only way. Legacy commands are documented only when necessary (e.g., `nix-collect-garbage`).
2. **Progressive Disclosure**: Start simple, add complexity gradually
3. **Verify Code Examples**: Test all Nix code snippets before committing
4. **Consistent Terminology**: Use same terms throughout
5. **Concept Transferability**: Focus on mental models that apply across all Nix usage (store mechanics, derivation evaluation, overlay composition)

## Common Tasks

### Adding a New Capsule

1. Create `pages/NN-topic-name.md` (next sequential number)
2. Add entry to `index.md` Table of Contents
3. Include Summary and Next Capsule sections
4. Update previous capsule's "Next Capsule" link

### Editing Existing Content

1. Keep numbering consistent when modifying
2. Update cross-references if section titles change
3. Ensure code examples work with current Nix version
