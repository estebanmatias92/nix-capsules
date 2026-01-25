# Nix Capsules 6: Functions and Imports

## Introduction

Welcome to the sixth Nix capsule. We have covered basic types. Now we introduce the engine of Nix: **Functions** and **Imports**.

These are the building blocks of reusability. In fact, as you will see by the end of this capsule, a **Flake** is nothing more than a giant function that takes `inputs` and returns `outputs`.

## Anonymous Functions (Lambdas)

In Nix, all functions are anonymous (often called **lambdas**). A function is defined by a single argument, a colon `:`, and the body.

```nix
nix-repl> x: x * 2
«lambda»
```

To use it, you apply an argument (no parentheses needed):

```nix
nix-repl> (x: x * 2) 5
10
```

You can give it a name by assigning it to a variable:

```nix
nix-repl> double = x: x * 2

nix-repl> double 10
20
```

## Multiple Parameters (Currying)

Technically, a Nix function only accepts **one** argument. To handle multiple arguments, we use a technique called **Currying**: a function returns _another function_.

```nix
# "mul" takes "a", and returns a function that takes "b"
nix-repl> mul = a: b: a * b

# Calling it passes arguments sequentially
nix-repl> mul 3 4
12
```

This allows **Partial Application** (baking in the first argument):

```nix
nix-repl> triple = mul 3

nix-repl> triple 10
30
```

## Argument Sets (Pattern Matching)

This is the most common pattern in NixOS configuration and Flakes. Instead of passing arguments one by one (`a: b:`), we pass a **single Attribute Set** and extract what we need inside the function.

```nix
nix-repl> add = { a, b }: a + b

nix-repl> add { a = 10; b = 2; }
12
```

### Exact Matching

By default, Nix is strict. If you pass extra args, it crashes.

```nix
nix-repl> add { a = 10; b = 2; c = 5; }
error: function 'anonymous lambda' called with unexpected argument 'c'
```

### The Ellipsis (`...`)

To allow extra arguments (common in module systems), add `...`:

```nix
nix-repl> add = { a, b, ... }: a + b

nix-repl> add { a = 10; b = 2; c = 99; }
12
```

### Default Values (`?`)

You can make arguments optional:

```nix
nix-repl> greet = { name ? "World" }: "Hello " + name

nix-repl> greet { }
"Hello World"

nix-repl> greet { name = "Nix"; }
"Hello Nix"
```

## Imports

The `import` keyword loads another `.nix` file and evaluates it.

**math.nix:**

```nix
# This file returns a function
{ a, b }: a + b
```

**repl:**

```nix
nix-repl> myFunc = import ./math.nix

nix-repl> myFunc { a = 10; b = 20; }
30
```

**Crucial Concept:** Variables don't "leak" between files. If you need a value from File A inside File B, you must **pass it as an argument**.

## The Flake Connection

Now, look at the `flake.nix` structure we'll be using in the next capsules.

```nix
{
  inputs = { ... };

  # LOOK HERE: It's a function with Pattern Matching!
  outputs = { self, nixpkgs }: {
     # ...
  };
}
```

The `outputs` section is just a **Function**.

1. It takes an attribute set `{ self, nixpkgs }` as its argument.
2. It uses **Pattern Matching** to grab `nixpkgs` from the inputs.
3. It returns an attribute set containing `packages`, `devShells`, etc.

This is why understanding functions is critical: **The entire Flake ecosystem is built on passing inputs to functions.**

## Practical Example: A Function-Based Flake

Let's refactor our standard Flake to verify we understand exactly how data flows.

**flake.nix:**

```nix
{
  description = "Functions Demo";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  # The Function Definition
  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    # We use the argument 'nixpkgs' to get our packages
    pkgs = nixpkgs.legacyPackages.${system};

    # A local helper function
    sayHello = name: pkgs.writeShellScriptBin "greet" ''
      echo "Hello, ${name}!"
    '';
  in
  {
    packages.${system} = {
      # We call our helper function
      default = sayHello "Student";
      custom  = sayHello "Advanced User";
    };
  };
}
```

Run it:

```bash
nix run .#default
# Output: Hello, Student!

nix run .#custom
# Output: Hello, Advanced User!
```

## Summary

1. **Functions** are usually anonymous: `x: x + 1`.
2. **Sets** are the standard argument type: `{ pkgs, ... }: ...`.
3. **Imports** load files; passing data requires functions.
4. **Flakes** are just functions that take `inputs` and return `outputs`.

## Next Capsule

Now that we understand the language, we are ready to build software. We will learn about the **Derivation**—the low-level instruction that tells Nix how to build a package.

> **[Nix Capsules 7: Our First Derivation](./07-our-first-derivation.md)**
