# Nix Capsules 17: Dependency Propagation

## Introduction

In the previous capsule, we learned how to customize packages using `.override`. Now, we will explore **Dependency Propagation**—how packages influence the environments of other packages that depend on them.

When building complex software, dependencies form a graph. If Package A depends on Package B, and Package B depends on Package C, does Package A automatically get access to Package C?

In Nix, the answer is usually **no**—unless you explicitly propagate it.

## Dependency Types Recap

As defined in the Manifesto, `stdenv` strictly separates dependencies:

| Attribute | Purpose | Effect |
| --- | --- | --- |
| **`nativeBuildInputs`** | **Tools** (Run-time on Build Machine) | Added to `$PATH`. |
| **`buildInputs`** | **Libraries** (Link-time on Host Machine) | Added to compiler search paths (`$C_INCLUDE_PATH`, etc). |
| **`propagatedBuildInputs`** | **Inherited Libraries** | Automatically adds the dependency to the `buildInputs` of any downstream package. |

## The Transitive Dependency Trap (Fail-First)

To understand *why* propagation exists, we must feel the pain of a transitive dependency failure.

Imagine a scenario:

1. `lib-base` provides a C header (`base.h`).
2. `lib-mid` provides a C header (`mid.h`) that **includes** `<base.h>`.
3. `app` includes `<mid.h>` and tries to compile.

Let's build this scenario. Create the following `flake.nix`:

**File:** `flake.nix`

```nix
{
  description = "Dependency Propagation Demo";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in rec {
    packages.${system} = {

      # 1. THE BASE LIBRARY
      lib-base = pkgs.stdenv.mkDerivation {
        name = "lib-base";
        dontUnpack = true;
        installPhase = ''
          mkdir -p $out/include
          echo "int base_val = 42;" > $out/include/base.h
        '';
      };

      # 2. THE MIDDLE LIBRARY (The Trap)
      lib-mid-broken = pkgs.stdenv.mkDerivation {
        name = "lib-mid-broken";
        dontUnpack = true;
        # We declare standard buildInputs
        buildInputs = [ lib-base ]; 
        installPhase = ''
          mkdir -p $out/include
          echo "#include <base.h>" > $out/include/mid.h
          echo "int mid_val = base_val + 1;" >> $out/include/mid.h
        '';
      };

      # 3. THE APPLICATION
      app-broken = pkgs.stdenv.mkDerivation {
        name = "app-broken";
        dontUnpack = true;
        # The app ONLY asks for the middle library
        buildInputs = [ lib-mid-broken ];
        buildPhase = ''
          echo "#include <mid.h>" > main.c
          echo "int main() { return mid_val; }" >> main.c
          gcc -o app main.c
        '';
        installPhase = "mkdir -p $out/bin; cp app $out/bin/";
      };
    };
  };
}
```

**Try to build the application:**

```bash
git init && git add flake.nix
nix build .#app-broken
```

**The Failure:**
`main.c:1:10: fatal error: mid.h: No such file or directory` (or `base.h: No such file or directory` depending on compiler behavior).
Nix isolated `app-broken`. It provided access to `lib-mid-broken`, but because `lib-mid-broken` did not *propagate* `lib-base`, the compiler inside `app-broken`'s sandbox has no idea where `base.h` is!

## Step 1: The Fix (`propagatedBuildInputs`)

If a library's public headers expose another library's headers, it **must** propagate that dependency.

Let's add the fixed versions to our `flake.nix`'s `packages` output:

```nix
      # ... (add this below app-broken)

      # 2. THE MIDDLE LIBRARY (Fixed)
      lib-mid-fixed = pkgs.stdenv.mkDerivation {
        name = "lib-mid-fixed";
        dontUnpack = true;
        # We change buildInputs to propagatedBuildInputs
        propagatedBuildInputs = [ lib-base ]; 
        installPhase = ''
          mkdir -p $out/include
          echo "#include <base.h>" > $out/include/mid.h
          echo "int mid_val = base_val + 1;" >> $out/include/mid.h
        '';
      };

      # 3. THE APPLICATION (Fixed)
      app-fixed = pkgs.stdenv.mkDerivation {
        name = "app-fixed";
        dontUnpack = true;
        buildInputs = [ lib-mid-fixed ]; # Depends on the fixed lib
        buildPhase = ''
          echo "#include <mid.h>" > main.c
          echo "int main() { return mid_val; }" >> main.c
          gcc -o app main.c
        '';
        installPhase = "mkdir -p $out/bin; cp app $out/bin/";
      };
```

**Try to build the fixed application:**

```bash
nix build .#app-fixed
```

**It succeeds!** `app-fixed` requested `lib-mid-fixed`, and Nix silently handed it `lib-base` as well.

## Step 2: The Mechanism (Glass Box)

How does `stdenv` magically know to include `lib-base` when building the app? It doesn't use a database; it uses plain text files written during the build.

Let's inspect the `lib-mid-fixed` package we just created:

```bash
nix build .#lib-mid-fixed

# Inspect the hidden Nix support directory
cat ./result/nix-support/propagated-build-inputs
```

**The Output:**
`/nix/store/...-lib-base`

When Nix starts compiling `app-fixed`, it looks at `lib-mid-fixed`, discovers this `nix-support` folder, reads the text file, and dynamically adds `/nix/store/...-lib-base` to the `$C_INCLUDE_PATH`. There is no magic—just text files tracking graphs.

## Step 3: Setup Hooks (Custom Environment Injection)

Propagation isn't just for C libraries. What if your package requires a custom environment variable (like `FRAMEWORK_DIR`) to be set for any package that depends on it?

You can inject a **Setup Hook**—a shell script that `stdenv` executes before building downstream packages.

Add these final packages to your `flake.nix`:

```nix
      # ... (add this below app-fixed)

      # A framework that exports an environment variable
      my-framework = pkgs.stdenv.mkDerivation {
        name = "my-framework";
        dontUnpack = true;
        installPhase = ''
          mkdir -p $out/nix-support
          
          # We write a bash script to the setup-hook file
          cat > $out/nix-support/setup-hook <<EOF
          export MY_FRAMEWORK_ACTIVE="true"
          export MY_FRAMEWORK_PATH="$out"
          echo "--- Custom Framework Hook Activated! ---"
          EOF
        '';
      };

      # An app that consumes the framework
      app-hook-test = pkgs.stdenv.mkDerivation {
        name = "app-hook-test";
        dontUnpack = true;
        buildInputs = [ my-framework ];
        
        # We test if the variable exists during the build!
        buildPhase = ''
          if [ "$MY_FRAMEWORK_ACTIVE" = "true" ]; then
            echo "Success: Framework path is $MY_FRAMEWORK_PATH" > result.txt
          else
            echo "Fail: Framework missing" > result.txt
            exit 1
          fi
        '';
        installPhase = "mkdir -p $out; cp result.txt $out/";
      };
```

**Test the hook:**

```bash
nix build .#app-hook-test
cat ./result/result.txt
# Output: Success: Framework path is /nix/store/...-my-framework
```

When `app-hook-test` declared `buildInputs = [ my-framework ]`, Nix automatically sourced the `setup-hook` script from the framework, executing your custom logic before the `buildPhase` even started.

## Summary

* **The Trap:** Including a library in `buildInputs` hides its dependencies from downstream consumers.
* **`propagatedBuildInputs`:** Tells Nix to expose this dependency to anyone who depends on *you*. Commonly used for C-headers and Python libraries.
* **The Glass Box:** Propagation is tracked simply by writing paths to `$out/nix-support/propagated-build-inputs`.
* **Setup Hooks:** You can execute arbitrary Bash scripts in the build environments of downstream consumers by placing a script at `$out/nix-support/setup-hook`.

## Next Capsule

In the next capsule, we'll explore **Store Internals**—diving deep into the difference between Input-Addressed and Content-Addressed derivations, and how multiple outputs split a single build into separate store paths.

> **[Nix Capsules 18: Store Internals](./18-store-internals.md)**
