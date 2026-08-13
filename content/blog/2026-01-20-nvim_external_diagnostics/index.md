+++
title="Working with external warnings and diagnostics in NVIM"
description="""
Compilers and tools in the VLSI and RTL world often produce a very large number
of warnings and errors when run.
I was interested in being able to quickly see and navigate all these diagnostics
directly in (Neo)Vim.

This is easily achievable using the `:make` command and compiler plugins, or by
manually generating diagnostics with a lua script.
"""
template="blog_post.html"

updated="2026-08-12"

[taxonomies]
tags=["nvim", "rtl"]
+++

While most modern programming languages feature very advanced editor
integrations especially through LSP server implementations, VLSI, RTL, and
(System)Verilog tooling is always a bit ... _different_.

Fortunately, these tools are not inherently bad, but rather a little more
old-fashioned. This means that while they might not be as straightforward
to use, the tools and techniques for an efficient workflow are already
out there.

In particular, I was interested in being able to quickly see and navigate to
all the numerous warnings and errors they produce directly in neovim.

I will use [verilator](https://www.veripool.org/verilator/) - an open-source
SystemVerilog simulator that works by transpiling RTL models to C++ code - as
an example for this post, but these same tools and techniques apply to everything
from commercial simulators and backend tools to any tool that generates errors
and warnings that are attached to a file location.

## The Quickfix List

As is so often the case, this exact feature is already supported in (neo)vim
without any external plugins.

In fact, for a simple C project using a `Makefile`, you don't even have to
configure anything!
The command `:make` will cause vim to call `make` with no arguments, capture
its output and parse it into the so-called quickfix list, which you can open
with `:cwindow`:

{{ centered_img(src="make_qf.png", desc="Errors produced by `:make` in the quickfix list.") }}

As you scroll through the quickfix list, vim will automatically jump to the location of
the errors and warnings.
Even without opening the quickfix list, you can jump between entries using `:cn` and `:cp`.

For more information about the quickfix list, see
[`:h quickfix`](https://neovim.io/doc/user/quickfix.html).


### The `makeprg` option and `cfile`

The `:make` command and quickfix list, despite its name, is not limited to
Makefiles and their output.
The `makeprg` option controls which command is invoked when `:make` is called.
For example, the following will cause it to run `cargo build`:
```vimscript
:set makeprg=cargo\ build
```

Any arguments you provide to the `:make` command will be appended to the end of
`makeprg`, unless the `$*` placeholder is used to specify where exactly the
arguments should be inserted:
```vimscript
:set makeprg=make\ $*\ verilate
:make MYDEFINE=1
make MYDEFINE=1 verilate
```

The `%` placeholder will be replaced with the path of the current file,
which is particularly useful for single-file linters or scripts:
```vimscript
:set makeprg=shellcheck\ %
" or
:set makeprg=python\ %
```

For long-running compilations and programs, running them directly in
vim can be a bit cumbersome.
In such cases, the `:cfile` command can be used to read program output that has
been written to a file:

```vimscript
:cfile program_output.log
```

The content will be used to populate the quickfix list just like the output
of the `:make` command.

For more information see
[`:h makeprg`](https://neovim.io/doc/user/options.html#'makeprg') and
[`:h cfile`](https://neovim.io/doc/user/quickfix.html#%3Acfile).

### The `errorformat` option

The `errorformat` option, in turn, contains one or more regex-like parsing
rules used to extract the source code location and other metadata from
the `:make` output or `:cfile`.

For example, consider the output of the aforementioned `verilator` tool:
```text
%Warning-DECLFILENAME: looong_path/tc_clk.sv:11:8: Filename 'tc_clk' does not match MODULE name: 'tc_clk_and2'
%Error-PINCONNECTEMPTY: other_path/trip_counter.sv:43:10: Instance pin connected by name with empty reference: 'overflow_o'
```
A parsing rule consists of literal text and `%`-prefixed placeholders.
For the above, a basic rule might look something like this:
```vimscript
:set errorformat=%%%t%*[a-zA-Z]-%*[^:]:\ %f:%l:%c:\ %m
```
It consists of the following components:

| Component             | Function                                                                                                 |
| -                     | -                                                                                                        |
| `%%`                  | Matches a single `%` character.                                                                          |
| `%t`                  | Matches a single character which determines the error type. (**E**rror, **W**arning, **I**nfo, **N**ote) |
| `%*[a-zA-Z]`          | Matches one or more lower or uppercase letters. This "consumes" the rest of E**rror**, W**arning**, I**nfo**, or N**ote**. |
| `-`                   | Matches a single `-` character.                                                                          |
| `%*[^:]`              | Matches one or more characters that are not a `:`.                                                       |
| `:`                   | Matches a single `:` character.                                                                          |
| <code>\\&nbsp;</code> | Matches a single space (` `).                                                                            |
| `%f`                  | Matches a file path.                                                                                     |
| `%l`                  | Matches a line number.                                                                                   |
| `%c`                  | Matches a column number.                                                                                 |
| `%m`                  | Matches an error message (a string).                                                                     |


[`:h error-file-format`](https://neovim.io/doc/user/quickfix.html#error-file-format)
contains documentation about how `errorformat` strings are interpreted, including
many more placeholders and tools.
Consider also having a look at existing compiler plugins as a reference (see below).

> [!NOTE]
> The above `errorformat` does not cover all possible verilator warnings and
> errors. See below for a more complete implementation that handles warnings
> without error code and without column.

### Compiler Plugins

(Neo)vim ships a set of pre-configured `makeprg` and `errorformat` values
for a number of common compilers and tools.
These take the form of so-called compiler plugins.

For a list of built-in compiler plugins, have a look at the
[`runtime/compiler`](https://github.com/neovim/neovim/tree/master/runtime/compiler)
folder of the (neo)vim source tree.
For a list of compiler plugins available in your current (neo)vim instance you can run:
```vimscript
:for f in globpath(&rtp, 'compiler/*.vim', 0, 1) | echo fnamemodify(f, ':t:r') | endfor
```

In typical vim fashion, the set of compiler plugins spans from slightly older tools,
such as different `fortran` flavours, to slightly more modern tools such as `gleam-build`.

A few that might be of interest:
- `cargo` and `rustc` for rust development.
- `eslint` and `tsc` for webdev.
- `tex` and `typst` for typesetting.

And even `modelsim_vcom`, which is the VHDL compiler in ModelSim!

It is worth having a look at the content of the compiler plugin file for a tool
you are intending to use.
Many of them feature extra options and settings you can control via global
variables.
For example, to determine the exact flags with which `cargo` is called,
the `cargo` compiler plugin considers the `g:cargo_makeprg_params` global:

```vimscript
" runtime/compiler/cargo.vim:
if exists('g:cargo_makeprg_params')
    execute 'CompilerSet makeprg=cargo\ '.escape(g:cargo_makeprg_params, ' \|"').'\ $*'
else
    CompilerSet makeprg=cargo\ $*
endif
```

### Custom Compiler Plugins: Verilator

If you find yourself often parsing the output of a tool that is not
yet included in (neo)vim's list of built-in compiler plugins, consider
adding a custom compiler plugin in your configuration.

On Linux, new compiler plugins should be placed in `$XDG_CONFIG_HOME/nvim/compiler/`,
while overrides to existing compiler plugins go in `$XDG_CONFIG_HOME/nvim/after/compiler/`.

For example, on my machine, to create a new `verilator` compiler plugin, I create
`~/.config/nvim/compiler/verilator.vim` with the following content:

```vimscript
" ~/.config/nvim/compiler/verilator.vim:
" Verilator warnings always start with "%Error" or "%Warning", optionally directly
" followed by an error code. If a location is known, it may be given with or
" without column number. Examples of errors:
"
" "%Warning: ..msg.."
" "%Error-DECLFORMAT: myfile:1: ..msg.."
" "%Error-PINCONNECT: myfile:1:2: ..msg.."
CompilerSet errorformat=%%%t%*[a-zA-Z]-%*[^:]:\ %f:%l:%c:\ %m,
			\%%%t%*[a-zA-Z]-%*[^:]:\ %f:%l:\ %m,
			\%%%t%*[a-zA-Z]:\ %f:%l:%c:\ %m,
			\%%%t%*[a-zA-Z]:\ %f:%l:\ %m,
```

See
[`:h write-compiler-plugin`](https://neovim.io/doc/user/usr_41.html#write-compiler-plugin) for
more info.

> [!NOTE]
> Unfortunately, the `%*[^:]` pattern used to match the error code causes it to not be
> shown in the quickfix list.
> Parsing it as a module (`%o`) will make it visible in the quickfix list, but hide the
> file name:
> ```vimscript
> CompilerSet errorformat=%%%t%*[a-zA-Z]-%o:\ %f:%l:%c:\ %m,
> 			\%%%t%*[a-zA-Z]-%o:\ %f:%l:\ %m,
> 			\%%%t%*[a-zA-Z]:\ %f:%l:%c:\ %m,
> 			\%%%t%*[a-zA-Z]:\ %f:%l:\ %m,
> ```

## Diagnostics

If you instead prefer to display external warnings and errors as
in-line diagnostics in the same style as LSP servers, that is also an option,
but requires a bit of lua scripting.

### The `vim.diagnostic` API

To display a set of diagnostics, first create a namespace to contain them:

```lua
local my_namespace = vim.api.nvim_create_namespace("my_namespace")
```

Next, configure how the diagnostics in this namespace should be displayed:
```lua
vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = false,
}, my_namespace)
```

Collect all your diagnostics for a given buffer into a table, and use
`vim.diagnostic.set()` to display them:

```lua
local bufnr = 0
local diagnostics = {
  {
    bufnr = bufnr, -- buffer
    lnum = 10, -- line number
    col = 0, -- column
    severity = vim.diagnostic.severity.WARN, -- severity
    message = "Something went wrong!", -- message
  }
}
vim.diagnostic.set(my_namespace, bufnr, diagnostics, {})
```


To remove all diagnostics, including before you re-apply a new set,
use `vim.diagnostic.reset()`:

```lua
vim.diagnostic.reset(my_namespace)
```

### Implementation
With this, you can write a lua function that parses any external source and
displays them as nvim diagnostics.

Have a look at the documentation of the tool you are using - many feature an
option for generating the diagnostics information in a machine readable format.
Verilator, for instance, can be instructed to write all errors and warnings
to a JSON file with standard SARIF formatting:

```bash
verilator --diagnostics-sarif --diagnostics-sarif-output log.json
```

In addition to seeing the errors inline, I like to use the excellent
[trouble.nvim](https://github.com/folke/trouble.nvim) to also show a quickfix-like
pane with all diagnostics.
If you prefer to use the quickfix list, you can also programmatically insert
the diagnostics there.

This approach, while a little bit more work, has the advantage of being
extremely flexible. For example, for my verilator output parsing, I added
simple reload and filtering capabilities:

```vimscript
" Parse + display verilator diagnostics file:
:VerilatorDiag log.json

" Reload diagnostics file:
:VerilatorDiag

" Only display diagnostics that contain the string "frontend", and remove any
" "UNOPTFLAT" and "UNUSEDSIGNAL" diagnostics:
:VerilatorDiagFilter frontend -UNOPTFLAT -UNUSEDSIGNAL

" Reset/clear the diagnostics:
:VerilatorDiagReset
```

A self-contained verilator sarif output parser and diagnostic generator with
filtering as described above can be found [here](@/blog/2026-01-20-nvim_external_diagnostics/verilator_sarif_parser.md).

## Notes & Resources
You can find my complete setup in my neovim configuration
[here](https://github.com/schilkp/dot/tree/main/neovim/.config/nvim/lua/schilk/utils/file_diagnostics).

## Changes
- `2026-08-12`:
    - Fixed small bugs in the sample implementation of `M.filter_check`
- `2026-08-13`:
    - Fixed `Changes` section and moved verilator sarif parser to dedicated page.
