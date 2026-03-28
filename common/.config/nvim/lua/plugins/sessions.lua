return {
  {
    "rmagatti/auto-session",
    config = function()
      require("auto-session").setup({
        auto_session_enabled = true,
        auto_save_enabled = true,
        auto_restore_enabled = true,
        auto_session_suppress_dirs = { "~/", "~/Downloads", "/" },
      })
    end,
  },
}