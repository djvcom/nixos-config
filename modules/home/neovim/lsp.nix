_:

{
  flake.modules.homeManager.neovim-lsp = {
    programs.nixvim.plugins.lsp = {
      enable = true;

      servers = {
        rust_analyzer = {
          enable = true;
          installCargo = false;
          installRustc = false;
        };
        ts_ls.enable = true;
        nil_ls = {
          enable = true;
          settings.nil.formatting.command = [ "nixfmt" ];
        };
        terraformls.enable = true;
      };

      keymaps = {
        lspBuf = {
          "gd" = {
            action = "definition";
            desc = "Go to definition";
          };
          "gr" = {
            action = "references";
            desc = "Find references";
          };
          "K" = {
            action = "hover";
            desc = "Hover info";
          };
          "<leader>ca" = {
            action = "code_action";
            desc = "Code action";
          };
          "<leader>rn" = {
            action = "rename";
            desc = "Rename symbol";
          };
        };
        diagnostic = {
          "[d" = {
            action = "goto_prev";
            desc = "Prev diagnostic";
          };
          "]d" = {
            action = "goto_next";
            desc = "Next diagnostic";
          };
        };
      };
    };
  };
}
