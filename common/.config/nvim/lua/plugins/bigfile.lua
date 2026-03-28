-- Large file performance optimization
-- Disables LSP for files > 10 MB or > 10k lines
return {
  "LunarVim/bigfile.nvim",
  event = "BufReadPre", -- Load before reading file
  opts = {
    filesize = 10, -- Threshold in MiB (10 MB)
    pattern = function(bufnr, filesize_mib)
      -- Check filesize first
      if filesize_mib > 10 then
        vim.notify(
          string.format("Big file detected: %.1f MB. Disabling LSP.", filesize_mib),
          vim.log.levels.WARN
        )
        return true
      end

      -- Check line count (must read file since buffer not loaded yet on BufReadPre)
      local ok, file_contents = pcall(vim.fn.readfile, vim.api.nvim_buf_get_name(bufnr))
      if ok and file_contents then
        local line_count = #file_contents
        if line_count > 10000 then
          vim.notify(
            string.format("Big file detected: %d lines. Disabling LSP.", line_count),
            vim.log.levels.WARN
          )
          return true
        end
      end

      return false
    end,
    features = {
      "lsp", -- Disable LSP (language servers)
    },
  },
}
