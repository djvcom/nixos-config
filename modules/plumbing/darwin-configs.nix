# Register all Darwin configurations
{ inputs, ... }:

{
  flake.darwinConfigurations = {
    macbook-personal = inputs.self.lib.mkDarwin {
      hostname = "macbook-personal";
    };
    macbook-work = inputs.self.lib.mkDarwin {
      hostname = "macbook-work";
    };
    # Alias for convenience
    macbook = inputs.self.lib.mkDarwin {
      hostname = "macbook-personal";
    };
  };
}
