# The Nix Capsules Manifesto (v2.2)

> _"Deconstruct, Fail, Then Automate"_

## I. Core Philosophy

### 1. Modernity First (The "Zero Legacy" Rule)

- **Prohibited (State Management):**
  - `nix-env`: Imperative, mutation-based package management.
  - `nix-channel`: Stateful channel management.
  - `nix-shell`: Legacy environment loader (replaced by `nix develop`).

- **Mandatory (Workflow):**
  - Modern CLI: `nix run`, `nix build`, `nix develop`, `nix profile`, `nix path-info`, `nix repl`.
  - Flakes: The exclusive mechanism for reproducibility.

- **Permitted Whitelist (Plumbing & Ecosystem):**
  - **`nix-store`**: Allowed strictly for advanced graph visualization (`-q --tree`, `--graph`) and closure inspection (`-qR`, `--references`) where `nix path-info` lacks readability or functionality.
  - **`patchelf`**: Allowed for inspecting binary RPATHs (Glass Box inspection of `stdenv` magic).
  - **`direnv`**: Allowed as the standard tool for automating environment loading.

### 2. The "Glass Box" Approach (No Magic)

- **Rule:** Never introduce a high-level abstraction without first inspecting the low-level mechanism.
- **Workflow:**
  1. **Inspect:** Look at the `.drv`, the JSON manifest, `nix-store --tree`, or use `nix-repl` to inspect attributes.
  2. **Suffering:** Do it the "hard way" (manual derivation, manual argument passing).
  3. **Automation:** Only then, introduce the helper (`stdenv`, `mkShell`, `callPackage`) as a relief.

- **Specific Constraint:** Do not treat `callPackage` as a black box. Explain **how** it works (reflection via `builtins.functionArgs`).

### 3. The "Fail-First" Pedagogy

- **Rule:** Intentionally guide the user into common pitfalls to teach constraints.
- **Key Examples:** The Git Trap (Cap 12), The Import Trap (Cap 13), The Sandbox Fail (Cap 07), The Missing Hash (Cap 10).

---

## II. The Narrative Arc

The content must flow linearly through these distinct identities:

1. **The Consumer (Caps 01-04):**
   - Focus: Using the Store, running binaries, understanding paths and hashes.

2. **The Linguist (Caps 05-06):**
   - Focus: Syntax, Sets, Functions. Only the subset required for Flakes.

3. **The Builder (Caps 07-10):**
   - Focus: `derivation` `stdenv` Runtime Dependencies.
   - _Strict separation of Build vs. Host._

4. **The Developer (Caps 11):**
   - Focus: Ephemeral environments (`devShells`).

5. **The Architect (Caps 12-13+):**
   - Focus: Project structure, Flakes, Composition, `callPackage`.

---

## III. Technical Standards

### 1. Dependency Strictness

- **`nativeBuildInputs`:** Must be defined as "Tools (Run-time on Build Machine)".
- **`buildInputs`:** Must be defined as "Libraries (Link-time on Host Machine)".
- **`packages`:** Must be defined _only_ as a `mkShell` syntactic shortcut (Capsule 11), never as a `mkDerivation` attribute.

### 2. Flake Purity

- **The "Import Trap":** Explicitly forbid `import <nixpkgs>` inside package files.
- **The Function Pattern:** Every `.nix` file must be a function that accepts dependencies as arguments (`{ stdenv, lib, ... }`).

### 3. Reproducibility

- All examples must use **Flakes** to pin dependencies.
- No "floating" URLs without checksums in fetchers.

---

## IV. Formatting & Style

### 1. Code Snippets

- **Executability (The "Hands-On" Rule):** Any example intended for the user to run must be **syntactically complete and buildable**. Do not use undefined placeholders (like `# ...` or `src = ./.;` without content) that cause generic syntax errors, unless the crash is a specific, intended lesson of the "Fail-First" pedagogy.
- **Self-Contained:** Snippets must include all necessary context (e.g., `inputs`) or explicitly reference a previous file the user has already created.
- **Commentary:** Must use **comments** to explain _why_, not just _what_.

### 2. Visual Cues

- **Didactic Checks:** Small mental quizzes.
- **Warnings:** For critical non-reversible actions or common misconceptions.

### 3. "Manifesto Check" (The Final Step)

- Before finalizing a capsule, ask: _Did I explain the magic? Did I let the user fail first? Is this modern Nix? Does the code actually run?_
