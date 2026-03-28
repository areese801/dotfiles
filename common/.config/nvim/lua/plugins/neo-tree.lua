return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = true, -- Show hidden/filtered items by default
        hide_dotfiles = false, -- Show dotfiles by default
        hide_gitignored = false, -- Show gitignored files by default
        hide_hidden = false, -- Show hidden files (Windows)
      },
      -- Disable netrw hijacking to prevent window ID conflicts
      hijack_netrw_behavior = "disabled",
      -- Follow current file and working directory
      follow_current_file = {
        enabled = true,
      },
      bind_to_cwd = true, -- Neo-tree root follows :cd changes
      use_libuv_file_watcher = true,
    },
    -- Disable auto-opening when session restores
    open_files_do_not_replace_types = { "terminal", "Trouble", "qf", "alpha" },
  },
}