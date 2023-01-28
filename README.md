# Neovim CPPlint HeaderGuard

Add header guard for current file.

With packer

```lua
use("patwie/include-guard.nvim")
```

Setup is


```lua
include_guard = require("include-guard")
include_guard.setup({ copyright_holder = "your_name", add_copyright = true })

-- Example short cut ("w" as wrap)
r.nnoremap("<leader>ww", require("include-guard").AddIncludeGuardAndCopyright)
r.nnoremap("<leader>wg", require("include-guard").AddIncludeGuard)
r.nnoremap("<leader>wc", require("include-guard").UpdateCopyright)

```
