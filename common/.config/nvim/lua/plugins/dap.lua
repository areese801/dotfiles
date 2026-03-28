return {
  -- Per-project DAP configurations
  {
    "ldelossa/nvim-dap-projects",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      local dap_projects = require("nvim-dap-projects")

      -- Search for project config on startup (deferred to avoid dashboard issues)
      vim.defer_fn(function()
        local ft = vim.bo.filetype
        local ignored_fts = { "snacks_dashboard", "dashboard", "alpha", "starter", "", "lazy", "mason" }
        local should_skip = false
        for _, ignored in ipairs(ignored_fts) do
          if ft == ignored then
            should_skip = true
            break
          end
        end
        if not should_skip then
          dap_projects.search_project_config()
        end
      end, 100)

      -- Also search when entering Python files to ensure configs are loaded
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "python",
        callback = function()
          -- Small delay to ensure dap-python is loaded
          vim.defer_fn(function()
            dap_projects.search_project_config()
          end, 200)
        end,
      })
    end,
  },

  -- Core DAP plugin
  {
    "mfussenegger/nvim-dap",
    lazy = true,
    dependencies = {
      {
        "rcarriga/nvim-dap-ui",
        dependencies = { "nvim-neotest/nvim-nio" },
        config = function()
          require("dapui").setup()
        end,
      },
    },
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Debug: Toggle Breakpoint" },
      {
        "<leader>dc",
        function()
          local ft = vim.bo.filetype
          -- Ignore non-debuggable filetypes
          local ignored_fts = { "snacks_dashboard", "dashboard", "alpha", "starter", "", "lazy", "mason" }
          for _, ignored in ipairs(ignored_fts) do
            if ft == ignored then
              vim.notify("Cannot debug from " .. (ft ~= "" and ft or "empty buffer"), vim.log.levels.WARN)
              return
            end
          end

          -- Ensure project configs are loaded before starting debug
          local dap_projects_ok, dap_projects = pcall(require, "nvim-dap-projects")
          if dap_projects_ok then
            dap_projects.search_project_config()
            -- Small delay to let config load
            vim.defer_fn(function()
              local dap = require("dap")
              -- Check if we have configurations
              if not dap.configurations[ft] or #dap.configurations[ft] == 0 then
                vim.notify(
                  "No debug configurations found for " .. ft .. ". Check :messages for details.",
                  vim.log.levels.WARN
                )
                return
              end
              dap.continue()
            end, 100)
          else
            require("dap").continue()
          end
        end,
        desc = "Debug: Start/Continue",
      },
      { "<leader>di", function() require("dap").step_into() end, desc = "Debug: Step Into" },
      { "<leader>dO", function() require("dap").step_over() end, desc = "Debug: Step Over" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Debug: Toggle UI" },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- Set up custom signs (icons) for breakpoints and debugging
      local signs = {
        DapBreakpoint = { text = "●", texthl = "DiagnosticError" },
        DapBreakpointCondition = { text = "●", texthl = "DiagnosticWarn" },
        DapBreakpointRejected = { text = "●", texthl = "DiagnosticInfo" },
        DapStopped = { text = "▶", texthl = "DiagnosticWarn" },
      }

      for sign_name, opts in pairs(signs) do
        vim.fn.sign_define(sign_name, opts)
      end

      -- Set up auto-open/close listeners after both plugins are loaded
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
  },
}