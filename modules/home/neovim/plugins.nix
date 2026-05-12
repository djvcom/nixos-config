_:

{
  flake.modules.homeManager.neovim-plugins = {
    programs.nixvim = {
      plugins = {
        nvim-tree = {
          enable = true;
          settings = {
            view.width = 30;
            filters.dotfiles = false;
          };
        };
        dap.enable = true;
        fugitive.enable = true;
        neogen = {
          enable = true;
          settings.snippet_engine = "luasnip";
        };
        web-devicons.enable = true;
      };

      keymaps = [
        {
          key = "<leader>e";
          action = ":NvimTreeToggle<CR>";
          options.desc = "Toggle file tree";
          mode = "n";
        }
        {
          key = "<leader>ng";
          action.__raw = ''function() require("neogen").generate() end'';
          options.desc = "Generate doc comment";
          mode = "n";
        }
        {
          key = "<leader>fr";
          action = ":checktime<CR>";
          options.desc = "Reload file from disk";
          mode = "n";
        }
        {
          key = "<leader>th";
          action = ":split | terminal<CR>";
          options.desc = "Terminal horizontal split";
          mode = "n";
        }
        {
          key = "<leader>tv";
          action = ":vsplit | terminal<CR>";
          options.desc = "Terminal vertical split";
          mode = "n";
        }
      ];
    };
  };
}
