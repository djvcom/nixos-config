_:

{
  flake.modules.homeManager.neovim-treesitter =
    { pkgs, ... }:
    {
      programs.nixvim.plugins.treesitter = {
        enable = true;
        settings.highlight.enable = true;
        grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          bash
          hcl
          javascript
          json
          lua
          markdown
          nix
          rust
          terraform
          toml
          tsx
          typescript
          yaml
        ];
      };
    };
}
