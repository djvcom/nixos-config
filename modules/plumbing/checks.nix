{ self, ... }:

{
  perSystem =
    { system, ... }:
    {
      checks =
        if system == "x86_64-linux" then
          {
            terminus = self.nixosConfigurations.terminus.config.system.build.toplevel;
            oshun = self.nixosConfigurations.oshun.config.system.build.toplevel;
          }
        else
          { };
    };
}
