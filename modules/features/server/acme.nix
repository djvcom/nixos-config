_:

{
  flake.modules.nixos.acme = {
    security.acme = {
      acceptTerms = true;
      defaults.email = "admin@djv.sh";
    };
  };
}
