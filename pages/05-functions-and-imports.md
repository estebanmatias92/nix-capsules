# Nix Capsules 5: Functions and Imports

## Introduction

Welcome to the fifth Nix capsule. In the previous capsule, we explored the Nix expression language's basic types and values. Now we introduce **functions** and **imports**—the building blocks for creating reusable, composable Nix code.

Functions enable abstraction in Nix, allowing you to write generic logic once and parameterize it for different use cases. Imports allow you to split your code across multiple files, organizing complex projects into manageable modules.

## Anonymous Functions

Nix functions are anonymous (lambdas) with a single parameter. The syntax is minimal: specify the parameter name, a colon, then the function body.

```nix
nix-repl> (x: x * 2)
«lambda»

nix-repl> (x: x * 2) 5
10
```

This function takes a parameter `x` and returns `x * 2`. Functions are values—you can store them in variables.

```nix
nix-repl> double = x: x * 2
nix-repl> double
«lambda»

nix-repl> double 7
14
```

Call a function by writing the function name followed by a space and the argument. No parentheses required for simple calls.

## Multiple Parameters via Currying

Nix functions accept only one parameter, but you achieve multiple parameters through **currying**—functions that return other functions.

```nix
nix-repl> mul = a: b: a * b
nix-repl> mul
«lambda»

nix-repl> mul 3
«lambda»

nix-repl> (mul 3) 4
12

nix-repl> mul 3 4
12
```

The expression `a: b: a * b` creates a function that takes `a` and returns another function taking `b`. This enables partial application:

```nix
nix-repl> triple = mul 3
nix-repl> triple 4
12

nix-repl> triple 10
30
```

Store `mul 3` as `triple`, then reuse it with different second arguments.

## Argument Sets with Pattern Matching

A powerful Nix feature: pattern matching against attribute sets in function parameters.

```nix
nix-repl> mul = s: s.a * s.b
nix-repl> mul { a = 3; b = 4; }
12
```

Access attributes directly from the set parameter. Even cleaner with destructuring:

```nix
nix-repl> mul = { a, b }: a * b
nix-repl> mul { a = 3; b = 4; }
12
```

The parameter `{ a, b }` requires the passed set to contain exactly those keys.

```nix
nix-repl> mul { a = 3; b = 4; c = 5; }
error: anonymous function at (string):1:2 called with unexpected argument `c'

nix-repl> mul { a = 3; }
error: anonymous function at (string):1:2 called without required argument `b'
```

Nix enforces exact attribute matching—extra or missing attributes cause errors.

## Default Values and Variadic Parameters

Provide default values for optional parameters:

```nix
nix-repl> mul = { a, b ? 2 }: a * b
nix-repl> mul { a = 3; }
6

nix-repl> mul { a = 3; b = 4; }
12
```

Allow additional attributes with `...`:

```nix
nix-repl> mul = { a, b, ... }: a * b
nix-repl> mul { a = 3; b = 4; extra = 10; }
12
```

Access the entire parameter set using the `@` pattern:

```nix
nix-repl> mul = s@{ a, b, ... }: a * b * s.extra
nix-repl> mul { a = 3; b = 4; extra = 5; }
60
```

## Imports

The `import` builtin loads a `.nix` file and evaluates it as an expression. Create three files:

**a.nix:**
```nix
3
```

**b.nix:**
```nix
4
```

**mul.nix:**
```nix
a: b: a * b
```

Load and use them:

```nix
nix-repl> a = import ./a.nix
nix-repl> b = import ./b.nix
nix-repl> mul = import ./mul.nix
nix-repl> mul a b
12
```

The imported file's scope is isolated—it doesn't inherit the caller's variables.

```nix
nix-repl> let x = 5; in import ./a.nix
error: undefined variable `x' at /home/user/a.nix:1:1
```

Pass data to imported modules by having them return functions:

**test.nix:**
```nix
{ a, b ? 3, message ? "default" }:
if a > b then "${message}: yes" else "${message}: no"
```

```nix
nix-repl> import ./test.nix { a = 5; message = "result"; }
"result: yes"
```

## Flakes and Modern Import Patterns

With Nix flakes, you typically use `flake.nix` files for modularity instead of manual imports:

**flake.nix:**
```nix
{
  description = "My Nix project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
  };
}
```

Use `nix develop` to enter a development shell and `nix run` to execute binaries.

## Summary

- Nix functions are anonymous and single-parameter; multiple parameters use currying
- Argument sets with pattern matching provide named, unordered parameters
- Default values and `...` enable optional and variadic parameters
- `import` loads external Nix files with isolated scope
- Modern flakes provide a standardized project structure with inputs and outputs

## Next Capsule

In the next capsule, we'll write our first **derivation**—Nix's fundamental building block for describing how to build software packages.

```nix
# Next: ./pages/06-our-first-derivation.md
```
