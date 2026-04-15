_:

{
  flake.modules.homeManager.neovim-rust =
    {
      lib,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv) isLinux;
    in
    {
      programs.nixvim = {
        plugins = {
          rustaceanvim = {
            enable = true;
            settings = {
              tools = {
                enable_clippy = true;
                test_executor = "neotest";
                crate_test_executor = "neotest";
              };
              server = {
                default_settings = {
                  rust-analyzer = {
                    cargo.allFeatures = true;
                    check.command = "clippy";
                    files.excludeDirs = [
                      "target"
                      ".git"
                      ".cargo"
                      ".direnv"
                    ];
                  };
                  inlayHints = {
                    lifetimeElisionHints.enable = "always";
                  };
                };
              };
              dap.adapter = lib.mkIf isLinux {
                type = "server";
                port = "\${port}";
                executable = {
                  command = "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb";
                  args = [
                    "--port"
                    "\${port}"
                  ];
                };
              };
            };
          };

          crates = {
            enable = true;
            settings = {
              lsp = {
                enabled = true;
                actions = true;
                completion = true;
                hover = true;
              };
              completion = {
                cmp.enabled = true;
                crates = {
                  enabled = true;
                  min_chars = 3;
                };
              };
            };
          };
        };

        keymaps = [
          {
            key = "<leader>re";
            action = ":RustLsp expandMacro<CR>";
            options.desc = "Expand macro";
            mode = "n";
          }
          {
            key = "<leader>rd";
            action = ":RustLsp debuggables<CR>";
            options.desc = "Rust debuggables";
            mode = "n";
          }
          {
            key = "<leader>rr";
            action = ":RustLsp runnables<CR>";
            options.desc = "Rust runnables";
            mode = "n";
          }
          {
            key = "<leader>rp";
            action = ":RustLsp parentModule<CR>";
            options.desc = "Go to parent module";
            mode = "n";
          }
        ];
      };
    };
}
