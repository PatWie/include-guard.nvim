# Neovim CPPlint HeaderGuard

Add header guard for current file.

Setup is


```lua
guard = require("include-guard")
guard.setup("Your name")

r.nnoremap("<leader>w", guard.AddIncludeGuard)

```
