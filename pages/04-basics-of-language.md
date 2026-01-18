# Nix Capsules 4: The Basics of the Language

## Introduction

In the previous capsule, we interacted with the environment using CLI tools. Now, we shift our focus to the **Nix expression language**.

Nix is a Domain-Specific Language (DSL). Before building packages, we must understand how to represent data. The language is:

- **Purely functional:** No side effects (writing to disk, network access) during evaluation.
- **Lazy:** Values are computed only when accessed.
- **Dynamic:** Types are resolved at runtime.

We will use the **Nix REPL** (Read-Eval-Print Loop) to verify the syntax.

## The REPL

To experiment with the language immediately, open the interactive console:

```bash
nix repl
```

You will see a prompt (`nix-repl>`). You can type expressions here to evaluate them instantly.

## Simple Types

### Primitives

Nix supports the usual primitives found in most languages.

```nix
nix-repl> 1 + 2
3
nix-repl> "Hello" + " World"
"Hello World"

```

- **Strings:** Enclosed in double quotes.
- **Multiline Strings:** Enclosed in two single quotes `'' ... ''`. Useful for scripts or configuration files, as they handle indentation intelligently.
- **Booleans:** `true`, `false`.
- **Null:** `null`.

### Paths

Paths are a first-class data type in Nix. They are written without quotes.

- **Absolute:** `/etc/nix/nix.conf`
- **Relative:** Must start with `./` to be valid. `./configuration.nix`.

```nix
nix-repl> ./foo
/absolute/path/to/current/directory/foo
```

If a path points to a file that exists, Nix will often copy it to the Nix Store when evaluated in a package context, returning the store path.

### Antiquotation (Interpolation)

You can insert the result of an expression into a string using `${}`.

```nix
nix-repl> name = "Nix"
nix-repl> "Hello ${name}"
"Hello Nix"
```

## Collections

### Lists

Lists are sequences of values separated by **whitespace**, not commas.

```nix
nix-repl> [ 1 2 "three" (2+2) ]
[ 1 2 "three" 4 ]
```

### Attribute Sets

The **Attribute Set** (often called "attrset" or "set") is the core data structure of Nix. It corresponds to a dictionary, hash map, or JSON object in other languages. It is an unordered collection of name-value pairs.

```nix
nix-repl> { a = 1; b = "foo"; }
{ a = 1; b = "foo"; }

```

You access values using the dot `.` operator.

```nix
nix-repl> s = { a = 1; b = 2; }
nix-repl> s.a
1
```

You can define nested sets directly:

```nix
nix-repl> { x.y.z = 10; }
{ x = { y = { z = 10; }; }; }
```

### Recursive Sets (`rec`)

By default, attributes in a set cannot refer to other attributes within the same set. To allow this self-reference, use the `rec` keyword.

```nix
nix-repl> rec {
            one = 1;
            two = one + 1;
          }
{ one = 1; two = 2; }
```

_Note: Use `rec` with caution. In complex derivations, it can sometimes lead to infinite recursion errors if not managed carefully._

## Language Constructs

### `let` Expressions

Use `let` to define local variables. The variables are only valid within the expression following the `in` keyword.

```nix
nix-repl> let
            x = 10;
            y = 5;
          in
            x + y
15
```

This is how we define private data or helper values before returning the final result (the expression after `in`).

### `inherit`

When constructing sets, it is common to assign a variable to a key with the same name. `inherit` is shorthand for this.

Instead of:

```nix
let x = 1; in { x = x; }
```

You can write:

```nix
let x = 1; in { inherit x; }
```

You can also inherit directly from another set:

```nix
nix-repl> s = { a = 1; b = 2; }
nix-repl> { inherit (s) a; }
{ a = 1; }
```

### `with`

The `with` expression brings all attributes of a set into the current scope.

```nix
nix-repl> s = { a = 10; b = 20; }
nix-repl> with s; a + b
30
```

While convenient, overuse of `with` can make code harder to read because it obscures where a variable comes from. It is most commonly seen at the top of files to bring packages into scope.

## Summary

- **Values:** Numbers, Strings (`"..."`, `''...''`), Paths (no quotes), Booleans.
- **Lists:** Whitespace separated `[ a b ]`.
- **Sets:** Key-value pairs `{ key = value; }`.
- **`rec`:** Allows keys inside a set to reference each other.
- **`let ... in`:** Defines local variables.
- **`inherit`:** Shorthand for assigning variables to keys of the same name.
- **`with`:** Adds a set's attributes to the scope.

## Next Capsule

We have covered the data structures. In the next capsule, **Functions and Imports**, we will learn how to create logic and modularize our Nix code by splitting it across multiple files.
