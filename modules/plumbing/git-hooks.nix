_:

{
  perSystem = {
    pre-commit.settings.hooks = {
      nixfmt.enable = true;
      statix.enable = true;
      deadnix.enable = true;
    };
  };
}
