{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    plugins = with pkgs.vimPlugins; [
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      luasnip
      cmp_luasnip

      telescope-nvim
      plenary-nvim

      (nvim-treesitter.withPlugins (p: [
        p.rust
        p.toml
        p.lua
        p.nix
        p.bash
        p.json
        p.yaml
        p.markdown
        p.javascript
        p.typescript
        p.tsx
      ]))

      catppuccin-nvim
      nvim-tree-lua
      nvim-web-devicons

      conform-nvim
      nvim-lint

      vim-fugitive

      neotest
      (pkgs.vimUtils.buildVimPlugin {
        name = "neotest-vitest";
        src = pkgs.fetchFromGitHub {
          owner = "marilari88";
          repo = "neotest-vitest";
          rev = "main";
          hash = "sha256-XpiZ95MhjIS99dBrNFfq8SfggdIeEFfOSu3THgmX3+s=";
        };
        # Skip require check - plugin has runtime dependencies on neotest
        doCheck = false;
        # Patch to fix async compatibility - hasVitestDependency uses async
        # file read (lib.files.read) but is_test_file is called synchronously,
        # causing "cannot read package.json" errors. Remove the broken call.
        postPatch = ''
          sed -i 's/return is_test_file and hasVitestDependency(file_path)/return is_test_file/' lua/neotest-vitest/init.lua
        '';
      })
      neotest-rust
      nvim-nio

      neogen
    ];

    extraLuaConfig = ''
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.expandtab = true
      vim.opt.shiftwidth = 2
      vim.opt.tabstop = 2
      vim.opt.smartindent = true
      vim.opt.termguicolors = true
      vim.opt.signcolumn = "yes"
      vim.opt.updatetime = 250
      vim.opt.clipboard = "unnamedplus"
      vim.g.clipboard = {
        name = "OSC 52",
        copy = {
          ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
          ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
        },
        paste = {
          ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
          ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
        },
      }

      vim.g.mapleader = " "

      vim.cmd.colorscheme("catppuccin-mocha")

      -- Neotest spawns a subprocess with "-u NONE" which has no plugins/parsers.
      -- Disable subprocess so discovery runs in main process where nix-installed
      -- treesitter parsers are available.
      local neotest_subprocess = require("neotest.lib.subprocess")
      neotest_subprocess.enabled = function() return false end

      require("neotest").setup({
        adapters = {
          require("neotest-vitest"),
          require("neotest-rust"),
        },
      })

      require("neogen").setup({
        snippet_engine = "luasnip",
      })
      vim.keymap.set("n", "<leader>ng", function() require("neogen").generate() end, { desc = "Generate doc comment" })

      require("nvim-tree").setup({
        view = { width = 30 },
        filters = { dotfiles = false },
      })
      vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file tree" })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "*",
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })

      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      vim.lsp.config("rust_analyzer", {
        cmd = { "rust-analyzer" },
        filetypes = { "rust" },
        root_markers = { "Cargo.toml", "rust-project.json" },
        capabilities = capabilities,
      })

      vim.lsp.enable("rust_analyzer")

      vim.lsp.config("ts_ls", {
        cmd = { "typescript-language-server", "--stdio" },
        filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
        root_markers = { "tsconfig.json", "package.json" },
        capabilities = capabilities,
      })

      vim.lsp.enable("ts_ls")

      vim.lsp.config("nil_ls", {
        cmd = { "nil" },
        filetypes = { "nix" },
        root_markers = { "flake.nix", "default.nix", ".git" },
        capabilities = capabilities,
        settings = {
          ["nil"] = {
            formatting = { command = { "nixfmt" } },
          },
        },
      })

      vim.lsp.enable("nil_ls")

      -- Formatting with conform.nvim
      require("conform").setup({
        formatters_by_ft = {
          nix = { "nixfmt" },
          rust = { "rustfmt" },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_fallback = true,
        },
      })

      -- Linting with nvim-lint
      require("lint").linters_by_ft = {
        nix = { "statix", "deadnix" },
      }

      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
        callback = function()
          require("lint").try_lint()
        end,
      })

      vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
      vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Find references" })
      vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover info" })
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
      vim.keymap.set("n", "<leader>cf", function() require("conform").format() end, { desc = "Format buffer" })
      vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
      vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })

      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })

      vim.keymap.set("n", "<leader>tn", function() require("neotest").run.run() end, { desc = "Run nearest test" })
      vim.keymap.set("n", "<leader>tc", function()
        require("neotest").output_panel.clear()
        require("neotest").run.run(vim.fn.expand("%"))
      end, { desc = "Clear panel and run file tests" })
      vim.keymap.set("n", "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, { desc = "Run file tests" })
      vim.keymap.set("n", "<leader>ts", function() require("neotest").summary.toggle() end, { desc = "Toggle test summary" })
      vim.keymap.set("n", "<leader>to", function() require("neotest").output.open({ enter = true }) end, { desc = "Show test output" })
      vim.keymap.set("n", "<leader>tp", function() require("neotest").output_panel.toggle() end, { desc = "Toggle output panel" })
      vim.keymap.set("n", "<leader>tl", function() require("neotest").run.run_last() end, { desc = "Run last test" })
      vim.keymap.set("n", "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end, { desc = "Debug nearest test" })

      local telescope = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", telescope.find_files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", telescope.live_grep, { desc = "Live grep" })
      vim.keymap.set("n", "<leader>fb", telescope.buffers, { desc = "Buffers" })
      vim.keymap.set("n", "<leader>fh", telescope.help_tags, { desc = "Help tags" })
    '';
  };
}
