return {
  -- Python debugging configuration
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    config = function()
      -- Function to find Python interpreter, prioritizing venv
      local function find_python()
        -- Check common venv locations in order of priority
        local venv_paths = {
          { path = vim.fn.getcwd() .. "/.venv/bin/python", name = "project .venv" },
          { path = vim.fn.getcwd() .. "/venv/bin/python", name = "project venv" },
          { path = vim.env.VIRTUAL_ENV and (vim.env.VIRTUAL_ENV .. "/bin/python"), name = "activated venv" },
        }

        for _, venv in ipairs(venv_paths) do
          if venv.path and vim.fn.executable(venv.path) == 1 then
            vim.notify(
              string.format("DAP Python: Using %s at %s", venv.name, venv.path),
              vim.log.levels.INFO,
              { timeout = 5000 }
            )
            return venv.path
          end
        end

        -- Fall back to system Python
        local system_python = vim.fn.exepath("python3") ~= "" and vim.fn.exepath("python3") or vim.fn.exepath("python")
        vim.notify(
          string.format("DAP Python: No venv found, using system Python at %s", system_python),
          vim.log.levels.WARN,
          { timeout = 5000 }
        )
        return system_python
      end

      local python_path = find_python()
      require("dap-python").setup(python_path)
    end,
  },

  -- Bash/Shell support
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {
          filetypes = { "sh", "bash", "zsh" },
        },
      },
    },
  },

  -- SQL support
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        sqlls = {},
      },
    },
  },

  -- Database management and SQL tools
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    keys = {
      { "<leader>D", "<cmd>DBUIToggle<CR>", desc = "Toggle DBUI" },
    },
    init = function()
      local data_path = vim.fn.stdpath("data")

      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_save_location = data_path .. "/dadbod_ui"
      vim.g.db_ui_tmp_query_location = data_path .. "/dadbod_ui/tmp"
      vim.g.db_ui_show_database_icon = true
      vim.g.db_ui_use_nvim_notify = true
      vim.g.db_ui_execute_on_save = false
      vim.g.db_ui_auto_execute_table_helpers = 1

      -- Load database connections from config file (version controlled, no secrets)
      local db_config_path = vim.fn.stdpath("config") .. "/lua/config/databases.lua"
      if vim.fn.filereadable(db_config_path) == 1 then
        dofile(db_config_path)
      else
        vim.notify("Database config not found at " .. db_config_path, vim.log.levels.WARN)
        vim.g.dbs = {}
      end
    end,
  },

  -- Configure blink.cmp for SQL completion
  {
    "saghen/blink.cmp",
    dependencies = {
      "kristijanhusak/vim-dadbod-completion",
    },
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      opts.sources.providers = opts.sources.providers or {}

      -- SQL completion
      opts.sources.providers.dadbod = {
        name = "Dadbod",
        module = "vim_dadbod_completion.blink",
        score_offset = 85, -- Higher priority for SQL completions
      }

      -- Add completions per filetype
      if not opts.sources.per_filetype then
        opts.sources.per_filetype = {}
      end

      -- SQL completions
      for _, ft in ipairs({ "sql", "mysql", "plsql" }) do
        if not opts.sources.per_filetype[ft] then
          opts.sources.per_filetype[ft] = {}
        end
        table.insert(opts.sources.per_filetype[ft], "dadbod")
      end

      return opts
    end,
  },

  -- Treesitter parsers for your languages
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "python",
        "bash",
        "sql",
        "markdown",
        "markdown_inline",
      })
    end,
  },

  -- Mason tool installer
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- Bash tools
        "bash-language-server",
        "shellcheck",
        "shfmt",
        -- SQL tools
        "sql-formatter",
        "sqlls",
      },
    },
  },

  -- Formatter configuration
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        sh = { "shfmt" },
        bash = { "shfmt" },
        sql = { "sql_formatter" },
        -- Explicitly disable Python formatting on save
        python = {},
      },
      formatters = {
        shfmt = {
          prepend_args = { "-i", "2", "-ci" },
        },
      },
    },
  },

  -- Linter configuration
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        sh = { "shellcheck" },
        bash = { "shellcheck" },
      },
    },
  },
}

