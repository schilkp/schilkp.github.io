+++
title="NVIM Diagnostics from Verilator SARIF output"
template="page.html"
path="blog/nvim-external-diagnostics/verilator-sarif-parser"
+++

Addendum to the post "[Working with external warnings and diagnostics in NVIM](@/blog/2026-01-20-nvim_external_diagnostics/index.md)".

A self-contained verilator sarif output parser and diagnostic generator with
filtering as described in the post above follows below:

```lua
local M = {}

M.verilator_namespace = vim.api.nvim_create_namespace("diag_verilator")
M.verilator_file = nil
M.verilator_exclude_filters = {}
M.verilator_include_filters = {}

function M.filter_check(file, msg, severity)
  local severity_lower = string.lower(severity or "")
  local diag = string.lower(file .. " " .. msg)

  -- Reject based on exclude filters:
  for _, filter in ipairs(M.verilator_exclude_filters) do
    local filter_lower = string.lower(filter)
    if string.find(diag, filter_lower) or string.find(severity_lower, filter_lower) then
      return false
    end
  end

  -- If any include filters are defined, check if we match one:
  if #M.verilator_include_filters > 0 then
    local any_filter_matches = false
    for _, filter in ipairs(M.verilator_include_filters) do
      local filter_lower = string.lower(filter)
      if string.find(diag, filter_lower) or string.find(severity_lower, filter_lower) then
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
