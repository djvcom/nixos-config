_:

{
  flake.modules.homeManager.neovim-formatting = {
    programs.nixvim = {
      plugins = {
        conform-nvim = {
          enable = true;
          settings = {
            formatters_by_ft = {
              nix = [ "nixfmt" ];
              rust = [ "rustfmt" ];
              terraform = [ "tofu_fmt" ];
              hcl = [ "tofu_fmt" ];
            };
            format_on_save = {
              timeout_ms = 500;
              lsp_fallback = true;
            };
            formatters = {
              tofu_fmt = {
                command = "tofu";
                args = [
                  "fmt"
                  "-"
                ];
                stdin = true;
              };
            };
          };
        };

        lint = {
          enable = true;
          lintersByFt = {
            nix = [
              "statix"
              "deadnix"
            ];
            terraform = [ "tflint" ];
          };
        };
      };

      autoCmd = [
        {
          event = [
            "BufWritePost"
            "BufReadPost"
          ];
          callback.__raw = ''function() require("lint").try_lint() end'';
        }
      ];

      keymaps = [
        {
          key = "<leader>cf";
          action.__raw = ''function() require("conform").format() end'';
          options.desc = "Format buffer";
          mode = "n";
        }
      ];
    };
  };
}
