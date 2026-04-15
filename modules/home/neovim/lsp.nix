_:

{
  flake.modules.homeManager.neovim-lsp = {
    programs.nixvim = {
      plugins.lsp = {
        enable = true;
        inlayHints = true;

        servers = {
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
            "gD" = {
              action = "declaration";
              desc = "Go to declaration";
            };
            "gr" = {
              action = "references";
              desc = "Find references";
            };
            "gI" = {
              action = "implementation";
              desc = "Go to implementation";
            };
            "gy" = {
              action = "type_definition";
              desc = "Go to type definition";
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
            "<leader>E" = {
              action = "open_float";
              desc = "Show diagnostic";
            };
          };
        };
      };

      extraConfigLua = ''
        vim.diagnostic.config({
          severity_sort = true,
          float = {
            border = 'rounded',
            source = true,
          },
        })
      '';
    };
  };
}
