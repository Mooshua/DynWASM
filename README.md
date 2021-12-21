# DynWASM

**WORK IN PROGRESS**- not ready for **any** use whatsoever.
*Documentation is speculative*

WASM compiler backend infrastructure, inspired by DynASM. Write a fast WASM compiler in your favorite language, without the added complexity of LLVM. DynASM may be easier to work with for some programmers due to it having a lexical relationship to the genrated code, rather than `emit("i32.const")`-like code generation.

## Features

| ✔️ | Good to go |
| -- | ---------- |
| ⏳ | **Work in progress** |
| ❌ | **Not started**, but planned |
| 🛑 | **Not planned**, see linked issues |

**Compiler**

| Feature | Status |
| ------- | ------ |
| Basic Instructions | ✔️ |
| Custom Sections    | ❌ |
| Atomics            | ❌ |
| Vectors            | ❌ |
| Optimization       | ❌ |
| Structs            | ❌ |

**Target Languages**

| Feature Matrix        | Lua  | JS  | C#  |
| --------------        | ---- | --- | --- |
| **Frontend Status**   | ⏳   | ❌ | ❌ |
| Futures               | ⏳   | ❌ | ❌ |
| Non-const vectors     | ⏳   | ❌ | ❌ |
| JIT Validation        | ❌   | ❌ | ❌ |

## Vocabulary

Important definitions which may be used throughout this document. *Please read the definitions even if you already are familiar with the term.*

| Word | Meaning |
| ---  | --- |
| Index | Anything in the WASM module is stored as a list in the binary format. An index points to one item in that list. For example, a function index points to one function in the code section. Indexes cannot be sparse (no skipping numbers!) |
| Symbol | A string which is converted to an index when building your WASM binary |
| Variable Index | An index which is represented as a variable in your code, but can be used anywhere a Symbol can be used. |
| String | Any value which can be defined at runtime (by *not* including double-quotes, uses a variable instead) or defined at compile time (by including double quotes). When defined at runtime, you can use any value (number, etc.), but at compile time, it must be unicode-compliant. Backslashes are *not* allowed. |

## The Syntax

DynWASM is very similar to DynASM: check out Peter Cawley's tutorial [here](https://corsix.github.io/dynasm-doc/) (and if you want to have a good time, his blog is [here](https://www.corsix.org/))

DynWASM will "expect" different syntax to be used while defining WASM binaries, but will allow you to do whatever, even if that would be illegal in your target language. This "go with the flow" allows you to be extraordinarily flexible with DynWASM, just like DynASM.

### Constants

Several constants are defined **which should not be used as variables in your DynWASM code.** (they are fine outside of the `|` pipes, though). The constants are:

| Name  | Value     |
| ----  | -----     |
| `i32` | `0x7F`    |
| `i64` | `0x7E`    |
| `f32` | `0x7D`    |
| `f64` | `0x7C`    |
| `v128`| `0x7B`    |
| `funcref` | `0x70`|
| `externref` | `0x6F` |
| `functype` | `0x60` |
| `limit_min` | `0x00` |
| `limit_minmax` | `0x01` |
| `const` | `0x00` |
| `mut`   | `0x01` |
| `empty` | `0x40` |

### Defining a function

DynWASM uses "macros" for most important junk, as it allows the frontend to quickly write to different sections of the WASM binary. Macros start with a `.`. Some macros you may use would be `.func` (defines a new function), `.future` (read below), `.export`, `.import`, and `.local`

> **Note:** `end` is a valid WASM instruction, but the `.end` macro MUST be used to end functions for internal purposes. You may define a new `.func` without ending the old one, but it is undefined behavior and will usually wipe the in-progress function (*Lua frontend*)

When defining your function, include argument and return types as constant vectors.

### Symbols

Most DynWASM directives will expect a `$` prefix to create a symbol, which will be internally stored by DynWASM.

Once a symbol has been defined with "$", it can be used throughout your code.

**Future declarations (as in, using a symbol which has not been defined yet) may not be supported by your language runtime. Make sure to check first!**

```cs
| .func $hello_world (i32 i64 i64) (i32 i64)
| .local #awesomeness i32
|   i32.const 1
|   i64.const 2
| .end
// ...
|   call $hello_world
```

You can also arrange for a function index to be placed in a variable by *not* using an `$`.

```cs
|.func hello_world (i32) (i32)
|   i32.const 5
|.end
//  This is functionally is similar to if you wrote
Symbol hello_world = DYNWASM_FUNC(...)
//  And can be used like a symbol:
Symbol hello_world_2 = hello_world
//  ...
|   call hello_world_2
|   call hello_world
//  which is interpreted similarly to
DYNWASM_EMIT("call", hello_world_2)
```
> *DYNWASM_\** functions were used for example, and are not actually present in generated code.

### Futures

Some frontends support using a symbol before it is defined. This is called a "future", and all indexes referencing a future will be filled in when the future is defined.

> **WARNING:** Leaving unresolved futures in a WASM binary (eg, failing to define a future) will result in a malformed binary.

```cs
| call $hello_future
// ...
|.func $hello_future (i32) (i32)
|   i32.const 1
|.end
```

You can also manually allocate a future at *any* time in the code. This will create a blank function, which will be expanded when you actually "define" your function:
```cs
|.future hello_world
|   call hello_world
//  Symbol hello_world = DYNWASM_ALLOC_FUTURE()
//  DYNWASM_EMIT("call", hello_world)
// ...
|.func hello_world (i32) (i32)
|   i32.const 1
|.end
```
> **NOTE:** This does not work with symbols. This is only for variable indexes, so `.future $symbol` is *not* allowed.

This is an obscure feature which is aimed towards compiler creators.
If you are generating two functions, each of which calls the other, it can be impossible to generate this sequence without $symbols, as you will be needing a function which does not exist.

To fix this, you may pre-allocate a function, which is what `.future` does.
```lua
--  Other func is not generated
if not otherFunc:Generated() then
    --  Allocate a future
    |.future otherFuncIdx
    --  We will generate the function to this index when we generate otherFunc
    otherFunc.Destination = otherFuncIdx
end
|.call otherFunc.Destination
--  ...
--  When generating otherFunc
if self.Destination then
|   .func self.Destination (unpack(self.Args)) (unpack(self.Ret))
else
--  We don't care what index/symbol it is
    local idx = nil
|   .func idx (unpack(self.Args)) (unpack(self.Ret))
    self.Destination = idx
end
--  ...
```

### Exports

You can export any function by index, using the `.export` macro. You should also define a name for the object, following the symbol.

```cs
|.func $hello_world () ()
|//  ...
|.end
|.export $hello_world "hello_world_func"
```

### Vectors

Vectors are defined using `()` parenthesis in your DynWASM code. Like strings, they can be non-const and point to a variable, but check with your language implementation first.

Vectors should generally be varardic numbers or consts to WASM types (see the table above). Using tables (eg, `({ myarg = i32})` may invoke undefined behavior.)

> **Note:** This example is in Lua, which converts the parenthesis into a table (`{}`), which supports unpack() for vararg arguments. **Check your language implementation before doing this!**

```cs
|.func $func_args_are_vectors (i32, unpack(rest_of_args) ) ()
|   //...
|.end
```