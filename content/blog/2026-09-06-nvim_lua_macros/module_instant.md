+++
title="NVIM: Transform SV Module Declaration to Instantiation"
template="page.html"
path="blog/nvim-lua-macros/module_instant"
+++

Addendum to the post "[NVIM: Writing Complex Macros / Transforms in Lua](@/blog/2026-09-06-nvim_lua_macros/index.md)".

Lua transform function to convert a SystemVerilog module declaration to an instantiation:

```lua
local M = {}

-- contains wrapper utils as discussed in post.
local utils = require("schilk.utils.macros.utils")

local SV_IDENTIFIER_PATTERN = "[%a_][%a_%$%d]*"

local function separate_comment(line)
  local idx, _ = line:find("//")
  if idx ~= nil then
    local comment = string.sub(line, idx)
    local line_content = string.sub(line, 1, idx - 1)
    return line_content, comment
  end

  local idx_start, _ = line:find("/%*")
  local idx_end, _ = line:find("%*/")
  if idx_start ~= nil and idx_end ~= nil then
    local comment = string.sub(line, idx_start, idx_end + 1)
    local line_content = string.sub(line, 1, idx_start - 1) .. string.sub(line, idx_end + 2)
    return line_content, comment
  end

  return line, ""
end

local function process_parameter_line(orig_line)
  -- Parameter line.

  -- Separate comment:
  local line, comment = separate_comment(orig_line)

  -- Separate trailing comma:
  local trailing_comma = ""
  local idx_comma, _ = line:find(",")
  if idx_comma ~= nil then
    trailing_comma = ","
    line = string.sub(line, 1, idx_comma - 1)
  end

  -- Strip default value:
  local idx_eq, _ = line:find("=")
  if idx_eq ~= nil then
    line = string.sub(line, 1, idx_eq - 1)
  end

  -- Isolate identifier:
  local ident_start, ident_stop = line:find(SV_IDENTIFIER_PATTERN .. "%s*$")
  if ident_start ~= nil and ident_stop ~= nil then
    local identifier = string.sub(line, ident_start, ident_stop)
    identifier = string.gsub(identifier, "%s", "")
    return "  ." .. identifier .. "( )" .. trailing_comma .. comment
  else
    -- Failed to grab identifier. Return orig string.
    return orig_line
  end
end

local function process_input_output_line(orig_line)
  -- Separate comment:
  local line, comment = separate_comment(orig_line)

  -- Separate trailing comma:
  local trailing_comma = ""
  local idx_comma, _ = line:find(",")
  if idx_comma ~= nil then
    trailing_comma = ","
    line = string.sub(line, 1, idx_comma - 1)
  end

  -- Remove trailing array indices:
  line = line:gsub("%[.*%]%s*$", "")

  -- Isolate identifier:
  local ident_start, ident_stop = line:find(SV_IDENTIFIER_PATTERN .. "%s*$")
  if ident_start ~= nil and ident_stop ~= nil then
    local identifier = string.sub(line, ident_start, ident_stop)
    identifier = string.gsub(identifier, "%s", "")
    return "  ." .. identifier .. "( )" .. trailing_comma .. comment
  else
    -- Failed to grab identifier. Return orig string.
    return orig_line
  end
end

function M.convert_to_instantiation(inp)
  local result = {}

  for _, line in ipairs(inp) do
    if line:find("^%s*parameter") ~= nil then
      local processed_line = process_parameter_line(line)
      table.insert(result, processed_line)
    elseif line:find("^%s*input") ~= nil or line:find("^%s*output") ~= nil then
      local processed_line = process_input_output_line(line)
      table.insert(result, processed_line)
    else
      table.insert(result, line)
    end
  end

  return result
end

function M.setup()
  vim.keymap.set("v", "gm", utils.visual_process_selection_lines(M.convert_to_instantiation), {
    desc = "♻️ Convert SV module to instantiation.",
    silent = true,
    noremap = true,
  })
  vim.api.nvim_create_user_command(
    "SvModuleInstant",
    utils.cmd_process_selection_lines(M.convert_to_instantiation),
    { range = true, desc = "Convert SV module to instantiation." }
  )
end

return M
```
