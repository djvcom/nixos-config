# Overlay to update opentelemetry-collector-contrib to v0.143.0
# Fixes nixpkgs bug where version shows 0.135.0 but components are 0.124.0
# See: https://github.com/NixOS/nixpkgs/pull/470448
final: prev:
let
  version = "0.143.0";

  # Builder for the collector
  builder = prev.opentelemetry-collector-builder.overrideAttrs (_: {
    inherit version;
    src = final.fetchFromGitHub {
      owner = "open-telemetry";
      repo = "opentelemetry-collector";
      rev = "cmd/builder/v${version}";
      hash = "sha256-SgPXQn3YW3fA1AZ8tsbxXGiThH/F+017OxCRpDsZCNM=";
    };
    vendorHash = "sha256-718IVq4iq4SaBBqtlAcbTNfvRxO+yB3gEI82KJdG1K8=";
  });

  # Source for otelcol-contrib (fixed-output derivation)
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
      hash = "sha256-HLX92aDgv00cxfoT1mjuz0AwBxl4fdgtio34mjHln7g=";
    };
    outputHash = "sha256-r7FzdF4Lbk1U70Eurvpaq31Y6Zvve5fAywAfHZBUA3M=";
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
    vendorHash = "sha256-eBteIkpOuwINrYlrnz1MPfKanqAUC3a+CMhELWf6zPU=";
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
