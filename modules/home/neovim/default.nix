{ inputs, config, ... }:

let
  nm = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.neovim =
    { ... }:
    {
      imports = [
        inputs.nixvim.homeModules.nixvim
        nm.neovim-lsp
        nm.neovim-rust
        nm.neovim-completion
        nm.neovim-telescope
        nm.neovim-treesitter
        nm.neovim-formatting
        nm.neovim-testing
        nm.neovim-plugins
      ];

      programs.nixvim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        byteCompileLua.enable = true;

        globals.mapleader = " ";

        opts = {
          number = true;
          relativenumber = true;
          expandtab = true;
          shiftwidth = 2;
          tabstop = 2;
          smartindent = true;
          termguicolors = true;
          signcolumn = "yes";
          updatetime = 250;
          clipboard = "unnamedplus";
        };

        colorschemes.catppuccin = {
          enable = true;
          settings.flavour = "mocha";
        };

        extraConfigLuaPre = ''
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
        '';
      };
    };
}
