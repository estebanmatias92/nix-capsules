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
error:
       ...
       error: function 'anonymous lambda' called with unexpected argument 'c'
       ...

nix-repl> mul { a = 3; }
error:
       ...
       error: function 'anonymous lambda' called without required argument 'b'
       ...
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

_Note: Nix only supports default argument (?) values when **destructuring attribute sets**._

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

**test.nix:**

```nix
x
```

```nix
nix-repl> let x = 5; in import ./test.nix
error:
       ...
       error: undefined variable 'x' at /home/user/test.nix:1:1:
       ...
```

The imported `test.nix` has no access to `x` from the caller's `let` binding.

## Passing Data via Functions

The solution is to have imported files return functions that accept parameters:

**test.nix:**

```nix
{ a, b ? 3, message ? "default" }:
if a > b then "${message}: yes" else "${message}: no"
```

```nix
nix-repl> :r      # Reload imported files again after the changes
nix-repl> import ./test.nix { a = 5; message = "result"; }
"result: yes"
```

_Note: You must log back into the REPL and import `test.nix` again, or use the `:r` command to reload the imported files.._

## Debugging with builtins.trace

Nix includes a built-in `trace` function for debugging. It prints a message during evaluation and returns the second argument:

**test.nix:**

```nix
{ a, b ? 3, trueMsg ? "yes", falseMsg ? "no" }:
if a > b
  then builtins.trace trueMsg true
  else builtins.trace falseMsg false
```

```nix
nix-repl> import ./test.nix { a = 5; trueMsg = "ok"; }
trace: ok
true
```

Key points:

- Multiple default parameters (`b ? 3`, `trueMsg ? "yes"`, `falseMsg ? "no"`)
- `builtins.trace(message, value)` prints the message and returns `value`
- **Lazy evaluation**: the trace only prints when the expression is evaluated

## Flakes: A Modern Alternative to Manual Imports

Flakes provide a standardized, reproducible way to organize Nix projects. Unlike manual imports, flakes use an `inputs`/`outputs` model where:

- **inputs** declare dependencies (other flakes, like nixpkgs)
- **outputs** expose packages, dev shells, and other artifacts

This approach is the modern standard for Nix projects, replacing ad-hoc file composition with a consistent structure.

**flake.nix:**

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

- Use `nix build` to build packages defined in `packages`
- Use `nix develop` to enter the development shell

_Note: `legacyPackages.x86_64-linux` is Nix's term for the traditional nixpkgs package collection. We'll explore how packages (derivations) are built in the next capsule._

## Summary

- Nix functions are anonymous and single-parameter; multiple parameters use currying
- Argument sets with pattern matching provide named, unordered parameters
- Default values and `...` enable optional and variadic parameters
- `import` loads external Nix files with isolated scope—no caller variables accessible
- Pass data to imported modules by having them return functions with parameters
- `builtins.trace(message, value)` enables debugging by printing during lazy evaluation
- Flakes provide a standardized `inputs`/`outputs` structure for project modularity
- Use `nix build` for packages and `nix develop` for development shells

## Next Capsule

In the next capsule, we'll write our first **derivation**—Nix's fundamental building block for describing how to build software packages.

```nix
# Next: ./07-our-first-derivation.md
```
