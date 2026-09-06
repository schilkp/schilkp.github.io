+++
title="NVIM: Writing Complex Macros / Transforms in Lua"
description="""
(Neo)Vim's macro system is a very powerful tool for quickly applying
a sequence of transformations over and over again.
However, in some rare cases, I find myself wanting a more generic way of
expressing such text transforms, with support for conditionals and logic.

This post shows how it is quite simple to write such transforms as Lua
functions, and register them both as visual mode mappings and user commands.
"""
template="blog_post.html"

[taxonomies]
tags=["nvim", "rtl"]
+++

(Neo)Vim's macro system is a very powerful tool for quickly applying
a sequence of transformations over and over again. The upcoming native
multicursor support in neovim is also shaping up to be an extremely ergonomic
and intuitive way of performing large, bulk edits very quickly.

However, in some rare cases, I find myself wanting a more generic way of
expressing such text tranforms, with support for conditionals and logic.
Something such as:

> If a given line contains the substring "XYZ" do one set of transformations,
> if it contains "ABC" do another set of transformations, and if it contains
> "123" delete it altogether.

This is especially the case when writing RTL in (System)Verilog, where I often
find myself needing to do structured and systematic text transformations.

Fortunately, neovim is configured and scripted in Lua, which makes this rather
simple to implement.

This blog post contains a short guide on how to write transforms as lua
functions, explains how to register them as bindings or commands, and includes
a few real-life examples of such transforms that I have found useful at the end.

## Wrapper Functions

I rely on two simple helper functions in my neovim configuration.

The first, given a Lua text-transform function that both accepts and returns
a list(-like table) of lines, returns a function which grabs the current selection,
applies the transform function, and replaces the current selection with its output:

```lua
-- Wrap a text-transformation function to make it simple to register
-- it as a visual mode text-transform mapping.
function visual_process_selection(processing_func)
  return function()
    -- Determine range of lines selected:
    local line_first = vim.fn.line("v")
    local line_last = vim.fn.line(".")
    if line_first > line_last then
      line_first, line_last = line_last, line_first
    end

    -- Retrieve selected lines:
    local bufn = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufn, line_first - 1, line_last, false)

    -- Process selected lines using the provided function:
    local processed_lines = processing_func(lines)

    -- Replace selected lines:
    vim.api.nvim_buf_set_lines(bufn, line_first - 1, line_last, false, processed_lines)

    -- Exit visual mode:
    local keys = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
    vim.api.nvim_feedkeys(keys, "m", false)
  end
end
```

The second, again given a Lua text-transform function that both accepts and
returns a list(-like table) of lines, returns a function that accepts an `opts`
table as given to a `nvim_create_user_command` callback, and again grabs the
current selection, applies the transform function, and replaces the current
selection with its output:

```lua
-- Wrap a text-transformation function to make it simple to register
-- it as a text-transforming user command.
function cmd_process_selection(processing_func)
  return function(opts)
    -- Get the range from the command (line1 and line2 are 1-indexed)
    local line_start = opts.line1
    local line_end = opts.line2

    -- Retrieve selected lines (nvim_buf_get_lines uses 0-indexed, exclusive end)
    local bufn = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufn, line_start - 1, line_end, false)

    -- Process selected lines using the provided function
    local processed_lines = processing_func(lines)

    -- Replace selected lines (nvim_buf_set_lines uses 0-indexed)
    vim.api.nvim_buf_set_lines(bufn, line_start - 1, line_end, false, processed_lines)
  end
end
```

## Example: Line Numbers

Using the utility functions above, we can take any Lua function that accepts
and returns a list(-like table) of strings, and easily register it as a
visual-mode mapping and user command to apply it to any text we are editing.
For example, consider the short example function below, which prepends a line-number
to each input line:

```lua
local function prepend_line_no(lines)
  local result = {}
  for idx, line in ipairs(lines) do
    table.insert(result, idx .. " | " .. line)
  end
  return result
end
```

We can register this function as a visual mode mapping and user command
as follows:
```lua
vim.keymap.set("v", "gQ", visual_process_selection(prepend_line_no), {
  desc = "Prepend line numbers",
  silent = true,
  noremap = true,
})
vim.api.nvim_create_user_command(
  "PrependLineNos",
  cmd_process_selection(prepend_line_no),
  { range = true, desc = "Prepend line numbers" }
)
```

Now, by selecting any text in visual mode and pressing `gQ` or typing `:'<,'>PrependLineNos`,
we can quickly and conveniently apply our `prepend_line_no` function:

Before:
```md
This is a sample piece
of input text with no
particular meaning.
```
After:
```md
1 | This is a sample piece
2 | of input text with no
3 | particular meaning.
```

## Example: Flip (System)Verilog Port Directions

I most commonly find myself writing and using such text transforms when
writing RTL code in a language like SystemVerilog.

For example, I often find myself having to change the direction of module
port declarations when routing signals through a hierarchy of modules.
This involves inverting the port direction (`input` <-> `output`), and adjusting
the port suffix (`*_i` <-> `*_o`, `*_ni` <-> `*_no`, ...).

The following Lua function describes this transformation:

```lua
function sv_flip_input_output(lines)
  local result = {}

  for _, line in ipairs(lines) do
    local modified_line = line

    -- Check if line contains input or output (ignoring leading whitespace)
    local trimmed = line:match("^%s*(.-)%s*$")

    if trimmed:match("^input%s") then
      -- Replace input with output
      modified_line = line:gsub("(%s*)input(%s)", "%1output%2")
      modified_line = modified_line:gsub("_i(%s*[,%s])", "_o%1")
      modified_line = modified_line:gsub("_i$", "_o")
      modified_line = modified_line:gsub("_ni(%s*[,%s])", "_no%1")
      modified_line = modified_line:gsub("_ni$", "_no")
    elseif trimmed:match("^output%s") then
      -- Replace output with input
      modified_line = line:gsub("(%s*)output(%s)", "%1input%2")
      modified_line = modified_line:gsub("_o(%s*[,%s])", "_i%1")
      modified_line = modified_line:gsub("_o$", "_i")
      modified_line = modified_line:gsub("_no(%s*[,%s])", "_ni%1")
      modified_line = modified_line:gsub("_no$", "_ni")
    end

    table.insert(result, modified_line)
  end

  return result
end
```

Consider the following example input:
```verilog
input logic clk_i,
input logic rst_ni,
// === I$ interface ==
input logic icache_ready_i,
output icache_req_t icache_req_o,
input icache_rsp_t icache_rsp_i,
// === Instr. Queue interface ==
input logic insn_q_ready_i, // A trailing comment!
output logic [Param.MAX_INSN_PER_FETCH-1:0] insn_q_entry_valid_o,
```

After applying the transform above, we are left with:
```verilog
output logic clk_o,
output logic rst_no,
// === I$ interface ==
output logic icache_ready_o,
input icache_req_t icache_req_i,
output icache_rsp_t icache_rsp_o,
// === Instr. Queue interface ==
output logic insn_q_ready_o, // A trailing comment!
input logic [Param.MAX_INSN_PER_FETCH-1:0] insn_q_entry_valid_i,
```

## Example: (System)Verilog Module Instantiation

As a more complex (but very useful!) example, consider the task
of instantiating a module in SystemVerilog.

> [!NOTE]
> For the non-hardware people reading this:
>
> A module declaration roughly corresponds to a function declaration, while
> a module instantiation roughly corresponds to a function call.
>
> In SystemVerilog, such modules tend to have many ports (function arguments),
> and the syntax for declaring and instantiating (calling) a module is very
> different.

Consider the following simple module declaration:
```verilog
module gshare #(
  parameter fe2_cfg_t Cfg,
  parameter type ft_t,
  parameter type ftq_entry_t,
  parameter type gshare_state_info_t,
  parameter type bp_train_info_t,
  parameter type ghist_update_t
) (
  input logic clk_i,
  input logic rst_ni,
  // Prediction Inputs:
  input logic [Cfg.VLEN-1:0] addr_i,
  input [Cfg.GSHARE_HIST_LEN-1:0] ghist_i,
  // Prediction:
  output gshare_state_info_t state_o,
  output logic pred_taken_o,
  output logic hit_o,
  // BP Training info input:
  input logic bp_train_info_valid_i,
  input bp_train_info_t bp_train_info_i,
  input [Cfg.GSHARE_HIST_LEN-1:0] bp_train_ghist_i
);
```

My module instantiation macro, whose full code you can find
[here](@/blog/2026-09-06-nvim_lua_macros/module_instant.md),
converts such a declaration into an (almost) fully-formed module
instantiation:
```verilog
module gshare #(
  .Cfg( ),
  .ft_t( ),
  .ftq_entry_t( ),
  .gshare_state_info_t( ),
  .bp_train_info_t( ),
  .ghist_update_t( )
) (
  .clk_i( ),
  .rst_ni( ),
  // Prediction Inputs:
  .addr_i( ),
  .ghist_i( ),
  // Prediction:
  .state_o( ),
  .pred_taken_o( ),
  .hit_o( ),
  // BP Training info input:
  .bp_train_info_valid_i( ),
  .bp_train_info_i( ),
  .bp_train_ghist_i( )
);
```

This allows me to quickly copy the module declaration to the place I want to
instantiate it, and do the bulk of the tedious editing with a single mapping.

You can find the full transform function to achieve this
[here](@/blog/2026-09-06-nvim_lua_macros/module_instant.md).
