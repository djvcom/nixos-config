# Overlay to upgrade Vaultwarden to 1.35.0 for SSO support
# SSO via OpenID Connect was introduced in 1.35.0 (2025-12-27)
# Remove this overlay once nixpkgs updates to >= 1.35.0
final: prev:
let
  version = "1.35.0";
  webvaultVersion = "2025.12.0";

  src = final.fetchFromGitHub {
    owner = "dani-garcia";
    repo = "vaultwarden";
    tag = version;
    hash = "sha256-Thj/I9eLngErUskKxnJ5Bd2Q9Hgp1e/6hWiiEyJ7lOQ=";
  };

  # Use pre-built web vault from dani-garcia/bw_web_builds releases
  webvault = final.stdenv.mkDerivation {
    pname = "vaultwarden-webvault";
    version = webvaultVersion;

    src = final.fetchurl {
      url = "https://github.com/dani-garcia/bw_web_builds/releases/download/v${webvaultVersion}/bw_web_v${webvaultVersion}.tar.gz";
      hash = "sha256-xEDCM9sgqAD5kGMJGRfXwkn7q9sUugjh8doSovXR6dM=";
    };

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/vaultwarden
      mv web-vault $out/share/vaultwarden/vault
      runHook postInstall
    '';

    meta = {
      description = "Pre-built web vault for Vaultwarden";
      homepage = "https://github.com/dani-garcia/bw_web_builds";
      license = final.lib.licenses.gpl3Plus;
    };
  };
in
{
  vaultwarden = prev.vaultwarden.overrideAttrs (oldAttrs: {
    inherit version src;

    # Set version shown in admin panel
    env.VW_VERSION = version;

    cargoDeps = final.rustPlatform.fetchCargoVendor {
      inherit src;
      name = "vaultwarden-${version}-vendor";
      hash = "sha256-/sKUAADlxzMOyThvYhFLK52oOePFQC1V8hF9Ay5Atis=";
    };

    passthru = oldAttrs.passthru // {
      inherit webvault;
    };
  });
}
