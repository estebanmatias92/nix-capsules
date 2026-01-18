# AGENTS.md - Nix Capsules Documentation Project

This is a documentation repository for **Nix Capsules**, an educational series about the **modern Nix package manager (Nix 3.x)**. The content consists of markdown files explaining Nix concepts with a focus on flakes, the unified CLI, and contemporary best practices.

## Modern Nix Standard

This documentation targets **Nix 3.x** with the following features enabled:

- **Flakes**: Use `flake.nix` for project-level dependency management
- **Unified CLI**: Use `nix` command (not legacy `nix-env`, `nix-instantiate`, etc.)
- **Experimental features**: `nix-command` and `flakes` enabled

### Modern vs Legacy Command Reference

| Legacy Command              | Modern Command / Equivalent                      | Notes |
| --------------------------- | ------------------------------------------------ | ----- |
| `nix-env -i pkg`            | `nix profile add nixpkgs#pkg`                    | Use unified CLI |
| `nix-env -u`                | `nix profile upgrade`                            | Use unified CLI |
| `nix-shell`                 | `nix develop` or `nix shell`                     | Use unified CLI |
| `nix-build`                 | `nix build`                                      | Use unified CLI |
| `nix-instantiate`           | `nix eval`                                       | Use unified CLI |
| `nix-store -q --references` | `nix path-info --json <path> \| jq -r '.[].references[]'` | No direct `nix store query` |
| `nix-store --gc`            | `nix store gc`                                   | Basic GC only |
| `nix-store --gc --list-roots` | (no direct modern equivalent)                  | Legacy only |
| `nix-store --gc --delete-generations` | `nix-collect-garbage --delete-old` or `nix profile wipe-history` | Use wrapper command |
| `nix-collect-garbage`       | `nix-collect-garbage` (still recommended)        | No modern equivalent, still actively used |

### Garbage Collection Note

The unified `nix` command provides only basic GC via `nix store gc`. For comprehensive cleanup including profile generations:

- **Basic GC**: `nix store gc`
- **Profile management**: `nix profile wipe-history --older-than Nd`
- **Full cleanup**: `nix-collect-garbage --delete-old` (recommended, no modern equivalent)

The `nix-collect-garbage` command is actively maintained and recommended in official documentation despite not being part of the unified `nix` CLI structure.

### Flake-first Approach

```nix
{
  description = "Example project";
  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; };
  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
  };
}
```

## Project Structure

```
prj-nix-capsules/
├── index.md              # Main landing page with table of contents
├── pages/                # Documentation pages (numbered sequentially)
│   ├── 01-why-you-should-give-it-a-try.md
│   ├── 02-install-on-your-running-system.md
│   └── ...
└── AGENTS.md             # This file
```

## Build/Lint/Test Commands

This is a **documentation-only project** with no build system, tests, or linting.

- No build commands required - markdown files are static content
- No test suite exists
- Optionally: `nix profile add nixpkgs#markdownlint-cli`

### Verification Commands

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
- Code blocks must specify language (```nix, ```bash)
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

## Best Practices

1. **Progressive Disclosure**: Start simple, add complexity gradually
2. **Verify Code Examples**: Test all Nix code snippets before committing
3. **Consistent Terminology**: Use same terms throughout

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
