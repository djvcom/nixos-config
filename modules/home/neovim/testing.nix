_:

{
  flake.modules.homeManager.neovim-testing =
    { pkgs, ... }:
    {
      programs.nixvim = {
        plugins.neotest = {
          enable = true;
          adapters = {
            vitest = {
              enable = true;
              package = pkgs.vimUtils.buildVimPlugin {
                name = "neotest-vitest";
                src = pkgs.fetchFromGitHub {
                  owner = "marilari88";
                  repo = "neotest-vitest";
                  rev = "f01addc6f07b79ef1be5f4297eafbee9e0959018";
                  hash = "sha256-XpiZ95MhjIS99dBrNFfq8SfggdIeEFfOSu3THgmX3+s=";
                };
                doCheck = false;
                postPatch = ''
                  sed -i 's/return is_test_file and hasVitestDependency(file_path)/return is_test_file/' lua/neotest-vitest/init.lua
                '';
              };
            };
            rust.enable = true;
          };
        };

        extraConfigLua = ''
          local neotest_subprocess = require("neotest.lib.subprocess")
          neotest_subprocess.enabled = function() return false end
        '';

        keymaps = [
          {
            key = "<leader>tn";
            action.__raw = ''function() require("neotest").run.run() end'';
            options.desc = "Run nearest test";
            mode = "n";
          }
          {
            key = "<leader>tc";
            action.__raw = ''
              function()
                require("neotest").output_panel.clear()
                require("neotest").run.run(vim.fn.expand("%"))
              end
            '';
            options.desc = "Clear panel and run file tests";
            mode = "n";
          }
          {
            key = "<leader>tf";
            action.__raw = ''function() require("neotest").run.run(vim.fn.expand("%")) end'';
            options.desc = "Run file tests";
            mode = "n";
          }
          {
            key = "<leader>ts";
            action.__raw = ''function() require("neotest").summary.toggle() end'';
            options.desc = "Toggle test summary";
            mode = "n";
          }
          {
            key = "<leader>to";
            action.__raw = ''function() require("neotest").output.open({ enter = true }) end'';
            options.desc = "Show test output";
            mode = "n";
          }
          {
            key = "<leader>tp";
            action.__raw = ''function() require("neotest").output_panel.toggle() end'';
            options.desc = "Toggle output panel";
            mode = "n";
          }
          {
            key = "<leader>tl";
            action.__raw = ''function() require("neotest").run.run_last() end'';
            options.desc = "Run last test";
            mode = "n";
          }
          {
            key = "<leader>td";
            action.__raw = ''function() require("neotest").run.run({ strategy = "dap" }) end'';
            options.desc = "Debug nearest test";
            mode = "n";
          }
        ];
      };
    };
}
