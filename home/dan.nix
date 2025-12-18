{ config, pkgs, lib, ... }:

{
  home.username = "dan";
  home.homeDirectory = "/home/dan";

  home.packages = with pkgs; [
    ripgrep
    fd
    eza
    jq
    gh
    rustup
    gcc
    yarn
    nodePackages.typescript-language-server
  ];


  home.sessionVariables = {
    DOCKER_HOST = "unix:///run/podman/podman.sock";
    EDITOR = "nvim";
  };

  programs.bash = {
    enableCompletion = true;
    enable = true;
    initExtra = ''
      export PATH="$HOME/.local/bin:$PATH"

      if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env"
      fi
    '';
    shellAliases = {
      la = "ls -lah";
      rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#terminus";
      vim = "nvim";
      # Git aliases (oh-my-zsh style)
      g = "git";
      gst = "git status";
      ga = "git add";
      gaa = "git add --all";
      gc = "git commit";
      gcm = "git commit -m";
      gco = "git checkout";
      gp = "git push";
      gl = "git pull";
      gd = "git diff";
      gds = "git diff --staged";
      gb = "git branch";
      glog = "git log --oneline --graph --decorate";
      # Tree view using eza
      tree = "eza --tree";
    };
  };

  programs.zellij = {
    enable = true;
    enableBashIntegration = false;
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      add_newline = false;
      character = {
        success_symbol = "[❯](green)";
        error_symbol = "[❯](red)";
      };
      directory.truncation_length = 3;
      git_branch.symbol = " ";
      rust.symbol = " ";
      nodejs.symbol = " ";
      package.disabled = true;
    };
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };

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
        p.typescript
        p.tsx
      ]))

      gruvbox-nvim
      nvim-tree-lua
      nvim-web-devicons
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

      vim.cmd.colorscheme("gruvbox")

      require("nvim-tree").setup({
        view = { width = 30 },
        filters = { dotfiles = false },
      })
      vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file tree" })

      require("nvim-treesitter.configs").setup({
        highlight = { enable = true },
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

      vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
      vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Find references" })
      vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover info" })
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
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

      local telescope = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", telescope.find_files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", telescope.live_grep, { desc = "Live grep" })
      vim.keymap.set("n", "<leader>fb", telescope.buffers, { desc = "Buffers" })
      vim.keymap.set("n", "<leader>fh", telescope.help_tags, { desc = "Help tags" })
    '';
  };

  programs.git = {
    enable = true;
    includes = [{
      path = "~/.config/git/identity";
    }];
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };

  programs.home-manager.enable = true;

  home.stateVersion = "25.05";
}
