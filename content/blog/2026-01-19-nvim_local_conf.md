+++
title="Managing project-specific NVIM configuration."
description="""
While my neovim configuration works out of the box for most of my projects, I
have increasingly encountered situations where I need to adjust certain aspects
on a per-project basis.

As with anything related to neovim configuration there are about 50 different
ways this can be achieved, and because neovim is usually configured with
executable code instead of declarative config files, a few gotchas that might
not be immediately obvious.
"""
template="blog_post.html"

[taxonomies]
tags=["nvim"]
+++

{{ toc() }}

## One size fits not quite all

While my [neovim configuration](https://github.com/schilkp/dot/tree/main/neovim/.config/nvim)
works out of the box for most of my projects, I have increasingly encountered
situations where I need to adjust certain aspects on a per-project basis.

For example, while doing some work with LLVM, I wanted to make use of the
MLIR and TableGen LSP servers.
While I could install these locally and add them to my configuration, I found
it quite beneficial to use the specific binaries built from the LLVM tree I was
working on - that way any changes I made to, for example, an MLIR dialect,
would immediately be available in the MLIR LSP after a quick re-compile.

There is nothing stopping me from adding such edge-case checks to my
main configuration - but that does not scale nicely and inevitably leaves
behind a whole bunch of configuration snippets I don't actively use, but don't
want to delete in case I go back to a project in the future.
I would much prefer a strategy that allows me to keep such per-project
configuration with the actual project.

As with anything related to neovim configuration there are about 50 different
ways this can be achieved, and because neovim is usually configured
with executable code instead of declarative config files, there are a few gotchas that
might not be immediately obvious.
Therefore I thought it might be useful to quickly write-up how the setup I
landed on works, and my thoughts behind why I built it in this way.

## Notable built-in features & plugins

First, a quick overview of some related built-in features and plugins that
are related to this subject:

### (Neo)Vim's `exrc` option

The `exrc` option is the historical solution to this problem, dating all
the way back to `vi`:

```vim
set exrc
```

On startup, when this option is set, vim will look for a `.vimrc` or `.exrc`
vimscript file in the current directory, while neovim will look for `.nvimrc`
or `.exrc` vimscript file or a `.nvim.lua` lua script file.
If one such file is found, after the system and main user configuration is
loaded, (neo)vim will `:source` this file, executing whatever code it contains.

> [!CAUTION]
> Without any additional security mechanism, this option will execute arbitrary
> code when opening your editor without any prompt or confirmation.
> NeoVim features some mitigation to make this less risky - see below.

Have a look at [`:h exrc`](https://neovim.io/doc/user/options.html#'exrc') for more information.

### NeoVim's `:trust` list

As executing arbitrary code when opening your editor in some repository you
just cloned from the internet is not an amazing idea, neovim introduced
`vim.secure.read()` and the associated `trust` list in `v0.11.5`
(released in 2022 - [`f1922e7`](https://github.com/neovim/neovim/commit/f1922e78a1df1b1d32779769432fb5586edf5fbb)).

When attempting to read a file for the first time using `vim.secure.read()`, neovim will
prompt the user to view the file and explicitly trust it:

```
:lua vim.secure.read("README.md")
exrc: Found untrusted code. To enable it, choose (v)iew then run `:trust`:
/home/schilkp/repos/schilkp.github.io/README.md
[i]gnore, (v)iew, (d)eny:
```

Only if the user actually marks the file as trusted, will the content be read.

The location and name of the file, a sha256 hash of its content, and the user
decision will be stored in the `trust` list, located at `$XDG_STATE_HOME/nvim/trust`:

```
d84ce812f0b22bf6fd2502d9deadbeef2229931192efef1abc0002091b40 /home/schilkp/repos/schilkp.github.io/README.md
! /home/schilkp/Downloads/random_project/sketchy_file_i_dont_trust.lua
```

After it has been trusted, successive secure reads of this file will complete
without a user prompt, unless the file content or location has changed.
In neovim, `vim.secure.read()` is used for reading the content of any file
discovered and sourced through the `exrc` option mechanism, making it significantly
less reckless
([`294910a`](https://github.com/neovim/neovim/commit/294910a1ffd11bea0081c2b92632628ef0462eb1)).

See [`:h vim.secure`](https://neovim.io/doc/user/lua.html#vim.secure) for more information.

### A long list of plugins

Per-project configuration is a common need, and there are also quite a few
plugins available to help you manage it, including
[`tpope/vim-projectionist`](https://github.com/tpope/vim-projectionist),
[`klen/nvim-config-local`](https://github.com/klen/nvim-config-local), and
[`direnv/direnv`](https://github.com/direnv/direnv.vim).

## My setup

With the `vim.secure.read()` mechanism, the `exrc` option in neovim is already
fairly close to what I want.
Its one major limitation for my use is that it is sourced _after_ my main
configuration and therefore after all plugins are configured and loaded.
This makes it tricky to do things like adding new plugins, or disabling LSP
servers and features that my main configuration enables - by the time a `.nvim.lua`
file is sourced, all this is already done.

For a similar reason, using one of the many plugins is also not so attractive,
as I ideally want my local configuration to be available before my plugin
manager sources all plugins.

Instead, I opted to implement a simple version of the `exrc` option directly
in my configuration:

```lua
--- localconfig.lua
local M = {}

M.CONFIG_FILE_NAMES = { ".schilk.nvim.lua" }

--- Look for local config file
function M.lookup()
  for _, filename in ipairs(M.CONFIG_FILE_NAMES) do
    filename = vim.fn.findfile(filename, ".;")
    if filename ~= "" then
      return vim.fn.fnamemodify(filename, ":p")
    end
  end
end

--- Find & load local config file
function M.source()
  local file = M.lookup()
  if not file or file == "" then
    return
  end
  local content = vim.secure.read(file)
  if content ~= nil then
    vim.api.nvim_command("source " .. file)
    vim.defer_fn(function()
      vim.notify("[local_config]: loaded local config file", vim.log.levels.INFO)
    end, 250)
  else
    vim.defer_fn(function()
      vim.notify("[local_config]: local config file found but not trusted!", vim.log.levels.WARN)
    end, 250)
  end
end

return M
```

This module looks for a file called `.schilk.nvim.lua` in the current or
any parent directories.
If one is found, the `vim.secure.read()` function is used, to allow me to
manually review and approve the content before it is actually sourced.

In my main `init.lua`, I can then use this module even before my plugin manager `lazy`
is initialized:

```lua
-- init.lua
require("local_config").source()
```

### Local Config Files

While the config file can contain arbitrary code, most of the time I want to change
some setting or behaviour of my main configuration.
I do this by storing information in the global `_G` table, which my main configuration
then checks for and applies if it exists.
For example, to install an additional plugin, I place one or more `lazy` plugin
specs in `_G.SCHILK_LOCAL_PLUGINS`:

```lua
-- Extra plugins to be inserted into the lazy spec
_G.SCHILK_LOCAL_PLUGINS = {
    'schilkp/my_cool_plugin'
}

```

In my main configuration, I then inject any plugins into the default list of
plugin specs before starting the plugin manager.

```lua
local plugins = {
    -- ... list of plugins ...
}

-- Inject local plugins:
_G.SCHILK_LOCAL_PLUGINS = _G.SCHILK_LOCAL_PLUGINS or {}
if _G.SCHILK_LOCAL_PLUGINS then
  for _, plugin in ipairs(_G.SCHILK_LOCAL_PLUGINS) do
    table.insert(plugins, plugin)
  end
end

require("lazy").setup(plugins)
```

For reference, here are some of the things which I often do in my local config files:
- Install and enable additional plugins, as shown above.
- Enable additional LSP servers from `lsp-config.nvim`.
- Disable LSP servers that I have usually enabled.
- Configure local, project-specific LSP servers, such as the aforementioned MLIR and TableGen LSPs.

### Shareability

The one big downside of this approach is that it is very tightly coupled to my neovim configuration,
and therefore these config files are not very useful to anyone else.
Unfortunately, because neovim configurations are all so incredibly different, I don't see a
great way of changing that.

This is reflected in my choice to name the files `.schilk.nvim.lua`: I doubt anyone else
will directly use them.

For this reason, I also typically don't check them into project git
repositories.
As I doubt that the LLVM project will be interested in a patch
that adds `.schilk.nvim.lua` to their `.gitignore`, to avoid having to keep
juggling that change around locally, I just ignore these files in all git repos
using a global `.gitignore`:

```
// ~/.gitconfig:
[core]
    excludesfile = /home/schilkp/.gitignore_global

// ~/.gitignore_global:
.schilk.nvim.lua
```

## Notes

You can find my complete setup directly in my neovim configuration
[here](https://github.com/schilkp/dot/blob/main/neovim/.config/nvim/lua/schilk/local_config/init.lua)
