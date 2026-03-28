-- Autosave on text change (PyCharm-style)
return {
  "okuuva/auto-save.nvim",
  event = { "InsertLeave", "TextChanged" },
  opts = {
    enabled = true,
    trigger_events = {
      immediate_save = { "BufLeave", "FocusLost" },
      defer_save = { "InsertLeave", "TextChanged" },
    },
    debounce_delay = 1000, -- 1 second delay after typing stops
    condition = function(buf)
      -- Only autosave for certain filetypes
      local filetype = vim.bo[buf].filetype
      local allowed_filetypes = {
        "python",
        "lua",
        "javascript",
        "typescript",
        "go",
        "rust",
        "sql",
      }

      -- Check if filetype is in allowed list
      for _, ft in ipairs(allowed_filetypes) do
        if filetype == ft then
          return true
        end
      end
      return false
    end,
    write_all_buffers = false,
    noautocmd = false,
  },
}
