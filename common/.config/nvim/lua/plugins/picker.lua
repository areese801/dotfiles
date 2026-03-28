-- Override <leader><leader> to include gitignored files like .env and .gitignore
-- while excluding bulk directories like virtual environments
return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader><leader>",
        function()
          Snacks.picker.files({
            hidden = true, -- show dotfiles
            ignored = true, -- show gitignored files
            exclude = {
              -- Version control
              ".git",

              -- Python
              "__pycache__",
              "*.py[oc]",
              ".venv",
              "venv",
              "virtualenv",
              "*.egg-info",
              "build",
              "dist",
              "wheels",
              ".ipynb_checkpoints",

              -- IDEs
              ".idea",
              ".fleet",
              ".vscode",
              ".zed",

              -- Node
              "node_modules",

              -- OS
              ".DS_Store",

              -- Misc caches
              ".mypy_cache",
              ".pytest_cache",
              ".ruff_cache",
              ".cache",
            },
          })
        end,
        desc = "Find Files (including .env, .gitignore)",
      },
    },
  },
}
