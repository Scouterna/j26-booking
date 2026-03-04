# Gleam Conventions, Patterns, and Anti-patterns

This document outlines conventions, patterns, and anti-patterns for Gleam code.
Conventions and anti-patterns are rules that should be adhered to always, while
patterns are to applied whenever the programmer thinks it would benefit their
code.

## Conventions

Gleam enforces `snake_case` for variables, constants, and functions, and
`PascalCase` for types and variants.

### Avoid unqualified importing of functions and constants

Always used the qualified syntax for functions and constants defined in other
modules.

```gleam
// Good
import gleam/list
import gleam/string

pub fn reverse(input: String) -> String {
  input
  |> string.to_graphemes
  |> list.reverse
  |> string.concat
}

// Bad
import gleam/list.{reverse}
import gleam/string.{to_graphemes, concat}

pub fn reverse(input: String) -> String {
  input
  |> to_graphemes
  |> reverse
  |> concat
}
```

Types and record constructors may be used with the unqualified syntax,
providing you think it does not make the code more difficult to read.

### Annotate all module functions

All module functions should have annotations for their argument types and for
their return type.

```gleam
// Good
fn calculate_total(amounts: List(Float), service_charge: Float) -> Float {
  list.fold(amounts, 0, int.add) * service_charge
}

// Bad
fn calculate_total(amounts, service_charge) {
  list.fold(amounts, 0, int.add) * service_charge
}

// Bad: missing return annotation
fn calculate_total(amounts: List(Float), service_charge: Float) {
  list.fold(amounts, 0, int.add) * service_charge
}
```

### Use result for fallible functions

All functions that can succeed or fail may return a result in Gleam.

Some languages use both the result and the option type for fallible functions,
but Gleam does not. Using results always makes code consistent and removes the
boilerplate that would otherwise be required to convert between result and
option. If there is no extra information to return for failure then the result
error type can be `Nil`.

Panics are not used for fallible functions, especially within libraries.
Panicking may be appropriate at the top level of application code, handling the
result returned by fallible functions.

```gleam
// Good
pub fn first(list: List(a)) -> Result(a, Nil) {
  case list {
    [item, ..] -> Ok(item)
    _ -> Error(Nil)
  }
}

// Bad: options
pub fn first(list: List(a)) -> option.Option(a) {
  case list {
    [item, ..] -> option.Some(item)
    _ -> option.None
  }
}

// Bad: panics/exceptions
pub fn first(list: List(a)) -> Result(a, Nil) {
  case list {
    [item, ..] -> item
    _ -> panic as "cannot get first of empty list"
  }
}
```

### Use singular for module names

Module names are singular, not plural.

```gleam
// Good
import app/user

// Bad
import app/users
```

This applies to all segments, not just the final one.

```gleam
// Good
import app/payment/invoice

// Bad
import app/payments/invoice
```

### Treat acronyms as single words

Acronyms are always written as if they were a single word.

```gleam
// Good
let json: Json = build_json()

// Bad
let j_s_o_n: JSON = build_j_s_o_n()
```

### Name conversion functions as prescribed

When naming a function that converts from one type to another, use the convention `x_to_y`.

```gleam
// Good
pub fn json_to_string(data: Json) -> String

// Bad
pub fn json_into_string(data: Json) -> String
pub fn json_as_string(data: Json) -> String
pub fn string_of_json(data: Json) -> String
```

If the module name matches the type name then do not repeat the name of the
type at the start of the function.

```gleam
// In src/my_app/identifier.gleam

// Good
pub fn to_string(id: Identifier) -> String

// Bad
pub fn identifier_to_string(id: Identifier) -> String
```

If there is a name for the encoding, format, or variant used in the conversion
function, then use that in the name of the function.

```gleam
// Good
pub fn date_to_rfc3339(date: Date) -> String

// Bad
pub fn date_to_string(date: Date) -> String
```

If there is a more descriptive name for the conversion operation then use that
instead.

```gleam
// Good
pub fn round(data: Float) -> Int

// Bad
pub fn float_to_int(data: Float) -> Int
```

### Name short-circuiting result functions as prescribed

Functions that return results should be given a name that is appropriate for
the domain and the operation they perform.

If the function is a special result-handling version of an existing function
that short-circuits when there is an error, then the `try_` prefix can be used,
so long as there is not a more appropriate domain-specific name.

```gleam
pub fn map(list: List(a), f: fn(a) -> b) -> List(b)

// Good
pub fn try_map(
  list: List(a),
  f: fn(a) -> Result(b, e),
) -> Result(List(b), e)

// Bad
pub fn monadic_bind(
  list: List(a),
  f: fn(a) -> Result(b, e),
) -> Result(List(b), e)
```

### Use the core libraries

Use these shared foundation packages rather than replicating their functionality:

- `gleam_stdlib`, `gleam_time`, `gleam_http`, `gleam_erlang`, `gleam_otp`, `gleam_javascript`

### Use the correct source code directory

- `src` — Application/library code. Can import from `dependencies` and `src/` only.
- `test` — Test code. Can import from any dependencies and any directory.
- `dev` — Development helpers. Can import from any dependencies and any directory.

## Patterns

### Design descriptive errors

Design error variants to describe what the error was in terms of your business
domain. Each variant should hold additional information about the error instance.

```gleam
// Good
pub type NotesError {
  NoteAlreadyExists(path: String)
  NoteCouldNotBeCreated(path: String, reason: simplifile.FileError)
  NoteCouldNotBeRead(path: String, reason: simplifile.FileError)
  NoteInvalidFrontmatter(path: String, reason: tom.ParseError)
}

// Bad: Not enough detail
pub type NotesError {
  NoteAlreadyExists
  NoteCouldNotBeCreated
}

// Bad: Designed around dependencies, not business domain
pub type NotesError {
  FileError(path: String, reason: simplifile.FileError)
  TomlError(path: String, reason: tom.ParseError)
}
```

### Comment liberally

Comments explain both _what_ the code does and _why_. Adding comments does not
mean the code itself can be written in an unclear way.

### Make invalid states impossible

Use Gleam's type system to precisely model your domain so invalid data cannot
be constructed.

```gleam
// Good
pub type Visitor {
  LoggedInUser(id: Int, email: String)
  Guest
}

// Bad: allows invalid states (id without email)
pub type Visitor {
  Visitor(id: Option(Int), email: Option(String))
}
```

## Anti-patterns

### Fragmented modules

Do not prematurely split up modules. Focus on the business domain and making
the best API. Large modules are not inherently a problem.

### Panicking in libraries

Libraries must not panic — always return `Result` types.

### Global namespace pollution

Place modules within a uniquely named directory matching the package name.

### Namespace trespassing

Do not place modules within a top-level directory that belongs to a different package.

### Using dynamic with FFI

Never use `Dynamic` for FFI types. Create new opaque types instead.

### Category theory overuse

Avoid complex category theory abstractions. Solve specific problems with specific solutions.
