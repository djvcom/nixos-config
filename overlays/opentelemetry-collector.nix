# Overlay to update opentelemetry-collector-contrib to v0.149.0
# Fixes nixpkgs bug where version shows 0.144.0 but components are 0.124.0
# See: https://github.com/NixOS/nixpkgs/pull/470448
final: prev:
let
  version = "0.149.0";

  builder = prev.opentelemetry-collector-builder.overrideAttrs (_: {
    inherit version;
    src = final.fetchFromGitHub {
      owner = "open-telemetry";
      repo = "opentelemetry-collector";
      rev = "cmd/builder/v${version}";
      hash = "sha256-XDX3/qXfunuSJO8yQKjUCgCeq7yBZTbg4TKXqehn6vo=";
    };
    vendorHash = "sha256-OqwRkswxG2BkGXs3FfT/m6I/9ASoDK3YMmgkvUvkzng=";
    doCheck = false;
  });

  contribSource = final.stdenv.mkDerivation {
    name = "otelcol-contrib";
    nativeBuildInputs = with final; [
      cacert
      git
      go
    ];
    src = final.fetchFromGitHub {
      owner = "open-telemetry";
      repo = "opentelemetry-collector-releases";
      rev = "v${version}";
      hash = "sha256-Ag0iDBCeIyVOqla3ysQHF/GIg4qT5FkSHej7eWroGVQ=";
    };
    outputHash = "sha256-D1IBpPYrfF6wRtKN9hF308BxdYHrutrMUzvMFr/wVP8=";
    outputHashMode = "recursive";
    patchPhase = ''
      patchShebangs .
    '';
    configurePhase = ''
      export HOME=$NIX_BUILD_TOP/home
      export GIT_SSL_CAINFO=$NIX_SSL_CERT_FILE
    '';
    buildPhase = ''
      ./scripts/build.sh -d otelcol-contrib -b ${builder}/bin/ocb -s true
    '';
    installPhase = ''
      mv ./distributions/otelcol-contrib/_build $out
      rm $out/build.log
    '';
  };
in
{
  opentelemetry-collector-builder = builder;

  opentelemetry-collector-contrib = final.buildGoModule {
    pname = "otelcol-contrib";
    inherit version;
    src = contribSource;
    proxyVendor = true;
    vendorHash = "sha256-k5CrES5YbYqK+txggaTy2SPtWDqdZ5fBM1bK/FGVdxY=";
    nativeBuildInputs = [ final.installShellFiles ];
    env.CGO_ENABLED = 0;
    ldflags = [
      "-s"
      "-w"
    ];
    postInstall = ''
      mv $out/bin/* $out/bin/otelcol-contrib
      installShellCompletion --cmd otelcol-contrib \
        --bash <($out/bin/otelcol-contrib completion bash) \
        --fish <($out/bin/otelcol-contrib completion fish) \
        --zsh <($out/bin/otelcol-contrib completion zsh)
    '';
    meta = with final.lib; {
      homepage = "https://github.com/open-telemetry/opentelemetry-collector-releases";
      description = "OpenTelemetry Collector Contrib";
      license = licenses.asl20;
      mainProgram = "otelcol-contrib";
    };
  };
}
