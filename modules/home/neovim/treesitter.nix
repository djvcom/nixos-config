_:

{
  flake.modules.homeManager.neovim-treesitter =
    { config, ... }:
    {
      programs.nixvim.plugins.treesitter = {
        enable = true;
        highlight.enable = true;
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
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
