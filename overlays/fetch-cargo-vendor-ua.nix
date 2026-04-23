_: prev:

# crates.io began blocking the default python-requests User-Agent in early
# 2026, so nixpkgs' fetch-cargo-vendor-util hits 403s on concurrent crate
# downloads. Patch the Python script to send a descriptive User-Agent.
# Remove once https://github.com/NixOS/nixpkgs/pull/512735 reaches
# nixpkgs-unstable.
{
  rustPlatform = prev.rustPlatform.overrideScope (
    _: _: {
      fetchCargoVendor =
        prev.buildPackages.callPackage "${prev.path}/pkgs/build-support/rust/fetch-cargo-vendor.nix"
          {
            inherit (prev) cargo;
            writers = prev.writers // {
              writePython3Bin =
                name: attrs: content:
                prev.writers.writePython3Bin name attrs (
                  if name == "fetch-cargo-vendor-util" then
                    builtins.replaceStrings
                      [ "    session = requests.Session()\n" ]
                      [
                        "    session = requests.Session()\n    session.headers[\"User-Agent\"] = \"nixpkgs fetchCargoVendor (https://github.com/NixOS/nixpkgs)\"\n"
                      ]
                      content
                  else
                    content
                );
            };
          };
    }
  );
}
