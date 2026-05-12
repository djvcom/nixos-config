_:

{
  flake.modules.homeManager.neovim-claudecode =
    { pkgs, ... }:
    {
      programs.nixvim = {
        extraPlugins = [
          (pkgs.vimUtils.buildVimPlugin {
            pname = "claudecode-nvim";
            version = "0-unstable-2025-05-12";
            src = pkgs.fetchFromGitHub {
              owner = "coder";
              repo = "claudecode.nvim";
              rev = "102d835c964069c9c5e37abaf05ae4f9c3ee6f00";
              hash = "sha256-h8wYaWBKjKrb7hYYKYs5yUS5RI0JVFo8Emcy99YK6Qw=";
            };
          })
        ];

        extraConfigLua = ''
          require("claudecode").setup({
            terminal = { provider = "native" },
          })
        '';

        keymaps = [
          {
            key = "<leader>cc";
            action = ":ClaudeCode<CR>";
            options.desc = "Toggle Claude Code";
            mode = "n";
          }
          {
            key = "<leader>cs";
            action = ":ClaudeCodeSend<CR>";
            options.desc = "Send selection to Claude";
            mode = "v";
          }
        ];
      };
    };
}
