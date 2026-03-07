_:

{
  perSystem = {
    pre-commit.settings.hooks = {
      nixfmt-rfc-style.enable = true;
      statix.enable = true;
      deadnix.enable = true;
    };
  };
}
