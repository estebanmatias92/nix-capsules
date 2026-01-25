# Nix Capsules 8: Store Path Mechanics

## Introduction

In previous capsules, we created files in the store like `/nix/store/g12...-hello`.

But why `g12...`? Why is it 32 characters long? And why does Nix claim to be "reproducible"?

The answer lies in **Store Path Mechanics**. Nix doesn't assign random IDs; it calculates them based on the **content** and **inputs** of the package. This ensures that if the inputs are identical, the output path is identical—guaranteeing reproducibility.

## The Foundation: NAR (Nix ARchive)

To hash a directory reliably, you need a deterministic format. Standard `tar` archives are not deterministic (they include timestamps, owner IDs, and file order can vary).

Nix uses its own format: **NAR** (Nix ARchive).

- **Sorted:** Files are always alphabetical.
- **Timeless:** All timestamps are set to 0 (Jan 1, 1970).
- **Ownerless:** User/Group IDs are ignored.
- **Permission-lite:** Only tracks "executable" or "regular".

Nix converts every package to a NAR before hashing it.

## The Hashing Pipeline

How do we get from a source file to `/nix/store/3sg4...-hello`?

1. **Serialization:** The directory/file is converted to NAR.
2. **Hashing:** The NAR is hashed using SHA-256.
3. **Truncation:** The hash is truncated to 160 bits (20 bytes).
4. **Encoding:** The result is encoded in **Base-32**.

### Base-32 Encoding

Nix uses a custom alphabet that avoids ambiguous characters (no `e`, `o`, `u`, `t` to avoid accidental offensive words, and no `1`, `l`, `I` confusion).

```text
0123456789abcdfghijklmnpqrsvwxyz
```

### Try it yourself

You can see the hash of any file using the modern CLI:

```bash
# Create a dummy file
echo "Hello Nix" > hello.txt

# Calculate its NAR hash
nix hash file --type sha256 ./hello.txt
# Output: sha256-s0j1... (standard format)

nix hash file --type sha256 --base32 ./hello.txt
# Output: 0kc...     (sri/nix format)
```

## Input-Addressed vs. Fixed-Output

There are two main ways Nix calculates the final store path.

### 1. Input-Addressed (The Standard)

This is used for **building software**. The hash of the output path is calculated based on the hash of the **inputs** (the derivation).

If you change **one character** in a comment in your source code, the input hash changes. Therefore, the output path changes.

- **Pro:** Guarantees that if the path is the same, the software was built exactly the same way.
- **Con:** A tiny change rebuilds the world (if `glibc` changes, everything depending on it changes).

### 2. Fixed-Output (The Exception)

This is used for **downloading files** (e.g., `fetchurl`). Since we can't know the hash of a download before we download it, we must **promise** Nix what the hash will be.

```nix
outputHash = "sha256-A...";
outputHashAlgo = "sha256";
```

- **Mechanism:** Nix trusts your promise. It calculates the store path using the _promised_ hash, not the derivation inputs.
- **Safety:** After downloading, Nix verifies the actual content matches the promise. If not, it fails.

## Inspecting the Derivation

We can see exactly what goes into the hash calculation by inspecting the `.drv` file.

```bash
# Build the hello package (if not already built)
nix build nixpkgs#hello

# Show the derivation structure
nix derivation show ./result
```

This returns a JSON object (Schema v4). Notice how dependencies are listed under `inputs.drvs`:

```json
{
  "derivations": {
    "72pl0rs7xi7vsniia10p7q8vl7f36xaw-hello-2.12.1.drv": {
      "args": [
        "-e",
        "/nix/store/l622p70vy8k5sh7y5wizi5f2mic6ynpg-source-stdenv.sh",
        "/nix/store/shkw4qm9qcw5sc5n1k5jznc83ny02r39-default-builder.sh"
      ],
      "builder": "/nix/store/lw117lsr8d585xs63kx5k233impyrq7q-bash-5.3p3/bin/bash",
      "env": {
        "NIX_MAIN_PROGRAM": "hello",
        "__structuredAttrs": "",
        "buildInputs": "",
        "builder": "/nix/store/lw117lsr8d585xs63kx5k233impyrq7q-bash-5.3p3/bin/bash",
        "cmakeFlags": "",
        "configureFlags": "",
        "depsBuildBuild": "",
        "depsBuildBuildPropagated": "",
        "depsBuildTarget": "",
        "depsBuildTargetPropagated": "",
        "depsHostHost": "",
        "depsHostHostPropagated": "",
        "depsTargetTarget": "",
        "depsTargetTargetPropagated": "",
        "doCheck": "1",
        "doInstallCheck": "1",
        "mesonFlags": "",
        "name": "hello-2.12.1",
        "nativeBuildInputs": "/nix/store/k9i66zardsrspa4mf0pxqxhbhb48jby1-version-check-hook",
        "out": "/nix/store/i3zw7h6pg3n9r5i63iyqxrapa70i4v5w-hello-2.12.1",
        "outputs": "out",
        "patches": "",
        "pname": "hello",
        "postInstallCheck": "stat \"${!outputBin}/bin/hello\"\n",
        "propagatedBuildInputs": "",
        "propagatedNativeBuildInputs": "",
        "src": "/nix/store/dw402azxjrgrzrk6j0p66wkqrab5mwgw-hello-2.12.1.tar.gz",
        "stdenv": "/nix/store/n1k7lm072r5k3g6v6wb91d2q4sxcxddm-stdenv-linux",
        "strictDeps": "",
        "system": "x86_64-linux",
        "version": "2.12.1"
      },
      "inputs": {
        "drvs": {
          "00kr1572g79ra9m29vxxnrfxm38nb82m-hello-2.12.1.tar.gz.drv": {
            "dynamicOutputs": {},
            "outputs": [
              "out"
            ]
          },
          "i0lswaixfnfr6j3qr9xrij8nq93rp9b5-bash-5.3p3.drv": {
            "dynamicOutputs": {},
            "outputs": [
              "out"
            ]
          },
          "qyk0syp0q2znsv9dpva6krckkcgnxbi1-stdenv-linux.drv": {
            "dynamicOutputs": {},
            "outputs": [
              "out"
            ]
          },
          "yy1bpiw7j0nsygs1iyrz465bplp948ck-version-check-hook.drv": {
            "dynamicOutputs": {},
            "outputs": [
              "out"
            ]
          }
        },
        "srcs": [
          "l622p70vy8k5sh7y5wizi5f2mic6ynpg-source-stdenv.sh",
          "shkw4qm9qcw5sc5n1k5jznc83ny02r39-default-builder.sh"
        ]
      },
      "name": "hello-2.12.1",
      "outputs": {
        "out": {
          "path": "i3zw7h6pg3n9r5i63iyqxrapa70i4v5w-hello-2.12.1"
        }
      },
      "system": "x86_64-linux",
      "version": 4
    }
  },
  "version": 4
}
```

If **anything** in `inputs` or `env` changes, the filename of this `.drv` file changes. Consequently, the calculated `outputs.out.path` changes.

## Store Path Validation

A valid store path looks like this:
`/nix/store/<32-char-hash>-<name>`

- **Hash:** The unique identifier.
- **Name:** Human-readable (for your convenience only; Nix mostly ignores it for logic).

**Rules:**

- **Name Chars:** `a-z`, `A-Z`, `0-9`, `+`, `-`, `.`, `_`, `?`, `=`.
- **Length:** The name is limited (fs limits), but the hash is always 32 chars.

## Practical Implications

Understanding this explains several Nix behaviors:

1. **Why can't I edit files in `/nix/store`?**
   If you modified a file, its content hash would no longer match the path hash. You would break the integrity of the system. That's why the store is Read-Only.
2. **Why do I see multiple versions of the same library?**
   `/nix/store/aaa...-openssl-1.1`
   `/nix/store/bbb...-openssl-1.1`
   These might be the same version of OpenSSL, but `bbb` was built with a different compiler flag or a newer generic builder. To Nix, they are completely different packages.
3. **Why are downloads checked?**
   In `fetchurl`, if you change the URL but keep the `sha256` the same, the store path **will not change**. Nix assumes that if the hash is the same, the content is the same, regardless of where it came from.

## Summary

- **NAR** is the deterministic file format used for hashing.
- **Input-Addressed:** Normal builds. Path depends on the derivation instructions (inputs).
- **Fixed-Output:** Downloads. Path depends on a declared hash.
- **The Butterfly Effect:** A change in a dependency changes the input hash, which changes the derivation hash, which changes the output path.

## Next Capsule

Now that we understand the math behind the paths, let's stop writing manual builders and use the tool that powers 99% of Nix packages: **stdenv**.

> **[Nix Capsules 9: Building with stdenv](./09-building-with-stdenv.md)**
