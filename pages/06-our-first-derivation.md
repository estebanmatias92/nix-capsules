# Nix Capsules 6: Our First Derivation

## Introduction

Welcome to the sixth Nix capsule. In the previous capsule, we learned about functions and imports. Now we finally write our first **derivation**—the core concept in Nix that describes how to build something.

A derivation is a recipe: it tells Nix what to build, what system it's for, what builder to use, and what dependencies it needs. Nix uses derivations to ensure reproducible builds.

## The Derivation Builtin

The `derivation` builtin creates a derivation from an attribute set. The set must include at least three attributes:

```nix
derivation {
  name = "myname";
  system = "x86_64-linux";
  builder = "/path/to/builder";
}
```

The attributes define:
- **name**: Identifier for this derivation (appears in the store path)
- **system**: Target platform (e.g., "x86_64-linux", "aarch64-darwin")
- **builder**: Executable that performs the build

Check your current system:

```nix
nix-repl> builtins.currentSystem
"x86_64-linux"
```

Create a minimal derivation:

```nix
nix-repl> d = derivation { name = "myname"; builder = "mybuilder"; system = builtins.currentSystem; }
nix-repl> d
«derivation /nix/store/z3hhlxbckx4g3n9sw91nnvlkjvyw754p-myname.drv»
```

The result is a `.drv` file—the derivation specification. Nix created it without building anything.

## Understanding .drv Files

A `.drv` file is an intermediate representation describing how to build a derivation. Think of it like a compiled object file in C:

- `.nix` source files → `.drv` object files → built outputs in `/nix/store`

View the derivation structure:

```bash
nix derivation show /nix/store/z3hhlxbckx4g3n9sw91nnvlkjvyw754p-myname.drv
```

```json
{
  "/nix/store/z3hhlxbckx4g3n9sw91nnvlkjvyw754p-myname.drv": {
    "outputs": {
      "out": {
        "path": "/nix/store/40s0qmrfb45vlh6610rk29ym318dswdr-myname"
      }
    },
    "inputSrcs": [],
    "inputDrvs": {},
    "platform": "x86_64-linux",
    "builder": "mybuilder",
    "args": [],
    "env": {
      "builder": "mybuilder",
      "name": "myname",
      "out": "/nix/store/40s0qmrfb45vlh6610rk29ym318dswdr-myname",
      "system": "x86_64-linux"
    }
  }
}
```

The out path is already known—Nix computes it from the derivation's inputs. The build product will appear there when built.

## Build Phases: Instantiate vs Realize

Nix separates derivation handling into two phases:

1. **Instantiation**: Parse and evaluate the Nix expression, produce `.drv` files
2. **Realization**: Build the derivations, produce outputs in the store

```bash
# Instantiation only
nix-instantiate hello.nix

# Instantiation + building
nix build .#hello
```

The `:b` command in `nix repl` performs realization:

```nix
nix-repl> :b d
error: a `mysystem' is required to build `/nix/store/...myname.drv', but I am a `x86_64-linux'
```

The fake builder and system don't match our platform—Nix correctly rejects this.

## Derivation Set Attributes

A derivation returns an attribute set with special attributes:

```nix
nix-repl> builtins.isAttrs d
true

nix-repl> builtins.attrNames d
[ "all" "builder" "drvAttrs" "drvPath" "name" "out" "outPath" "outputName" "system" "type" ]
```

- `d.drvPath`: Path to the `.drv` file
- `d.outPath`: Path where build output will appear
- `d.type`: Always "derivation" for derivation sets

```nix
nix-repl> d.outPath
"/nix/store/40s0qmrfb45vlh6610rk29ym318dswdr-myname"
```

## Referring to Other Derivations

Derivations can reference other derivations. Nix automatically converts derivation sets to their output paths:

```nix
nix-repl> :l <nixpkgs>
Added 3950 variables.

nix-repl> coreutils
«derivation /nix/store/1zcs1y4n27lqs0gw4v038i303pb89rw6-coreutils-8.21.drv»

nix-repl> builtins.toString coreutils
"/nix/store/8w4cbiy7wqvaqsnsnb3zvabq1cp2zhyz-coreutils-8.21"
```

Nix converts derivation sets to strings via their `outPath` attribute—this enables path interpolation:

```nix
nix-repl> "${coreutils}"
"/nix/store/8w4cbiy7wqvaqsnsnb3zvabq1cp2zhyz-coreutils-8.21"

nix-repl> "${coreutils}/bin/true"
"/nix/store/8w4cbiy7wqvaqsnsnb3zvabq1cp2zhyz-coreutils-8.21/bin/true"
```

## A Working Derivation

Use `coreutils/bin/true` as a builder—it succeeds but produces no output:

```nix
nix-repl> d = derivation {
  name = "myname";
  builder = "${coreutils}/bin/true";
  system = builtins.currentSystem;
}
nix-repl> :b d
builder for `/nix/store/...myname.drv' failed to produce output path
```

The builder ran successfully but didn't create the output path. Real derivations must create their `$out` directory or file.

## The $out Environment Variable

Nix reserves an output path for each derivation and passes it as `$out` to the builder. The builder must create something at `$out`.

```nix
nix-repl> d.out
«derivation /nix/store/...myname.drv»

nix-repl> d == d.out
true
```

For single-output derivations, `out` is the derivation itself.

## Summary

- The `derivation` builtin creates derivations from attribute sets
- `.drv` files describe builds; actual outputs go to `/nix/store`
- Nix separates instantiation (creating `.drv`) from realization (building)
- Derivations reference each other via their `outPath`
- The `$out` environment variable is where builders must place outputs

## Next Capsule

In the next capsule, we'll write a **working derivation** that actually builds something—a simple program.

```nix
# Next: ./pages/07-working-derivation.md
```
