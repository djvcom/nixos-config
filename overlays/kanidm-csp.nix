# Overlay to upgrade Kanidm to 1.8.5 for CSP form-action fix
# The CSP fix was merged in PR #4011 (Dec 11, 2025) and released in 1.8.5
# Remove this overlay once nixpkgs updates to >= 1.8.5
final: prev:
let
  version = "1.8.5";

  src = final.fetchFromGitHub {
    owner = "kanidm";
    repo = "kanidm";
    tag = "v${version}";
    hash = "sha256-lJX/eObXi468iFOzeFjAnNkPiQ8VbBnfqD1518LDm2s=";
  };
in
{
  kanidm_1_8 = prev.kanidm_1_8.overrideAttrs (_: {
    inherit version src;

    cargoDeps = final.rustPlatform.fetchCargoVendor {
      inherit src;
      name = "kanidm-${version}-vendor";
      hash = "sha256-LjlXd2zJ2eXr/dyCsbwlzv3Qntg2b0mudtWGtc0V7Lc=";
    };
  });
}
