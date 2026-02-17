+++
title="Working with external warnings and diagnostics in NVIM."
description="""
Compilers and tools in the VLSI and RTL world often produce a very large number
of warnings and errors when run.
I was interested in being able to quickly see all and navigate these diagnostics 
directly in (Neo)Vim.

This is easily achievable using the `:make` command and compiler plugins, or by
manually generating diagnostics with a lua script.
"""
template="blog_post.html"

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

{{ centered_img(src="make_qf.png", desc="Errors produced by `:make` in the quick-fix list.") }}

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

And even `modelsim_vcom`, which is the VHDL compiler in modelsim!

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

On linux, new compiler plugins should be placed in `$XDG_CONFIG_HOME/nvim/compiler/`,
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
If you prefer to use the quickfix list, you can also programatically insert
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

## Notes & Resources

You can find my complete setup in my neovim configuration
[here](https://github.com/schilkp/dot/tree/main/neovim/.config/nvim/lua/schilk/utils/file_diagnostics).

A self-contained verilator sarif output parser and diagnostic generator with filtering
as described above follows below:

```lua
local M = {}

M.verilator_namespace = vim.api.nvim_create_namespace("diag_verilator")
M.verilator_file = nil
M.verilator_exclude_filters = {}
M.verilator_include_filters = {}

function M.filter_check(file, msg, severity)
  local severity_lower = string.lower(severity)
  local diag = file .. " " .. msg

  -- Reject based on exclude filters:
  for _, filter in ipairs(M.verilator_exclude_filters) do
    local filter_lower = string.lower(filter)
    if string.find(diag, filter) or string.find(severity_lower, filter_lower) then
      return false
    end
  end

  -- If any include filters are defined, check if we match one:
  if #M.verilator_include_filters > 0 then
    local any_filter_matches = false
    for _, filter in ipairs(M.verilator_include_filters) do
      local filter_lower = string.lower(filter)
      if string.find(diag, filter) or string.find(severity_lower, filter_lower) then
        any_filter_matches = true
      end
    end

    if not any_filter_matches then
      return false
    end
  end

  return true
end

function M.generate_diags(log_file)
  local file = io.open(log_file, "r")
  if not file then
    error("Could not open verilator sarif file: " .. log_file)
    return
  end

  local content = file:read("*all")
  file:close()
  local success, data = pcall(vim.json.decode, content)
  if not success then
    error("Invalid JSON/SARIF in file: " .. log_file)
    return
  end

  if not data["runs"] or #data["runs"] ~= 1 then
    error("Invalid JSON/SARIF in file - not exactly one run: " .. log_file)
    return
  end
  data = data["runs"][1]

  if not data["results"] then
    error("Invalid JSON/SARIF in file - no results: " .. log_file)
    return
  end
  data = data["results"]

  -- per-bufnr diagnostics:
  local diagnostics = {}

  -- Iterate through data:
  for _, result in ipairs(data) do
    local rule_id = ""
    if result["ruleId"] then
      rule_id = result["ruleId"] .. ": "
    end
    local message = rule_id .. (result["message"]["text"] or "No message")

    local level = vim.diagnostic.severity.INFO
    if result["level"] == "error" then
      level = vim.diagnostic.severity.ERROR
    elseif result["level"] == "warning" then
      level = vim.diagnostic.severity.WARN
    end

    if not result["locations"] or #result["locations"] == 0 then
      goto continue
    end

    local loc = result["locations"][1]["physicalLocation"]

    if not loc or not loc["artifactLocation"] or not loc["region"] then
      goto continue
    end

    local file_path = loc["artifactLocation"]["uri"]:gsub("^file://", "")
    local start_line = loc["region"]["startLine"] or 1
    local start_column = (loc["region"]["startColumn"] or 1) - 1

    if not M.filter_check(file_path, message, result["level"]) then
      goto continue
    end

    local bufnr = vim.fn.bufadd(file_path)
    if not bufnr then
      error("Error")
      return
    end

    if not diagnostics[bufnr] then
      diagnostics[bufnr] = {}
    end

    table.insert(diagnostics[bufnr], {
      bufnr = bufnr,
      lnum = start_line - 1,
      col = start_column,
      message = message,
      severity = level,
      source = "verilator",
    })

    ::continue::
  end

  -- Set Diagnostics, per-buffer:
  local cnt = 0
  vim.diagnostic.reset(M.verilator_namespace)
  for bufnr, diags in pairs(diagnostics) do
    vim.diagnostic.set(M.verilator_namespace, bufnr, diags, {})
    cnt = cnt + #diags
  end

  -- Notification:
  local filters = {}
  for _, f in ipairs(M.verilator_include_filters) do
    table.insert(filters, f)
  end
  for _, f in ipairs(M.verilator_exclude_filters) do
    table.insert(filters, "-" .. f)
  end
  local filters_str = ""
  if #filters ~= 0 then
    -- all filters joined by spaces:
    filters_str = "\nFilters: " .. table.concat(filters, " ")
  end
  vim.notify("Found " .. cnt .. " verilator diagnostics." .. filters_str)
end

function M.reload()
  if M.verilator_file then
    M.generate_diags(M.verilator_file)
  end
end

function M.cmd_diags(args)
  if #args.fargs == 0 then
    if not M.verilator_file then
      error("No verilator log file set.")
      return
    end
    M.generate_diags(M.verilator_file)
  else
    local abs_path = vim.fn.fnamemodify(args.args, ":p")
    M.verilator_file = abs_path
    M.generate_diags(abs_path)
  end
end

function M.cmd_reset()
  M.verilator_file = nil
  M.verilator_exclude_filters = {}
  M.verilator_include_filters = {}
  vim.diagnostic.reset(M.verilator_namespace)
end

function M.cmd_clear()
  vim.diagnostic.reset(M.verilator_namespace)
end

function M.cmd_filter(args)
  M.verilator_exclude_filters = {}
  M.verilator_include_filters = {}
  for _, arg in ipairs(args.fargs) do
    if vim.startswith(arg, "-") then
      table.insert(M.verilator_exclude_filters, arg:sub(2))
    else
      table.insert(M.verilator_include_filters, arg)
    end
  end
  if M.verilator_file then
    M.generate_diags(M.verilator_file)
  end
end

function M.setup()
  vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = false,
  }, M.verilator_namespace)
  vim.api.nvim_create_user_command("VerilatorDiagReset", M.cmd_reset, { nargs = 0 })
  vim.api.nvim_create_user_command("VerilatorDiagClear", M.cmd_clear, { nargs = 0 })
  vim.api.nvim_create_user_command("VerilatorDiag", M.cmd_diags, { nargs = "?", complete = "file" })
  vim.api.nvim_create_user_command("VerilatorDiagFilter", M.cmd_filter, { nargs = "*" })
end

return M
```
