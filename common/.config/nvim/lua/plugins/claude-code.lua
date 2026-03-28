return {
  "greggh/claude-code.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required for git operations
  },
  config = function()
    require("claude-code").setup({
      -- You can customize the configuration here if needed
      -- Default keymaps:
      -- <C-,>: Toggle Claude Code terminal
      -- <leader>cC: Continue previous conversation
      -- <leader>cV: Verbose mode
    })
  end,
}