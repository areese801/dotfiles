-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Delete without yanking (use black hole register)
vim.keymap.set({ "n", "v" }, "d", '"_d', { desc = "Delete without yanking" })
vim.keymap.set({ "n", "v" }, "D", '"_D', { desc = "Delete to end without yanking" })
vim.keymap.set({ "n", "v" }, "x", '"_x', { desc = "Delete char without yanking" })
vim.keymap.set({ "n", "v" }, "X", '"_X', { desc = "Delete char before without yanking" })

-- Use leader+d for cut (delete with yank to clipboard)
vim.keymap.set({ "n", "v" }, "<leader>d", '"+d', { desc = "Cut to clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>D", '"+D', { desc = "Cut to end to clipboard" })

-- Exit insert mode with jk
vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- File save
vim.keymap.set("n", "<leader>fs", "<cmd>w<cr>", { desc = "Save file" })

-- Copy filename/path to clipboard
vim.keymap.set("n", "<leader>fy", function()
  local name = vim.fn.expand("%:t")
  if name == "" then
    vim.notify("Buffer has no file", vim.log.levels.WARN)
    return
  end
  vim.fn.setreg("+", name)
  vim.notify("Copied: " .. name)
end, { desc = "Copy filename to clipboard" })

vim.keymap.set("n", "<leader>fY", function()
  local name = vim.fn.expand("%:t")
  if name == "" then
    vim.notify("Buffer has no file", vim.log.levels.WARN)
    return
  end
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path)
end, { desc = "Copy full path to clipboard" })
