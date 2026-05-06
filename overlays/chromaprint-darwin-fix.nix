_: prev:

# chromaprint's FFmpegAudioReaderTest is killed with SIGKILL (exit 137) in
# the macOS Nix sandbox — the test tries to open audio via FFmpeg which hits
# a sandbox file-I/O restriction. Disable the test suite on Darwin.
# Remove once nixpkgs skips this test unconditionally on Darwin.
{
  chromaprint = prev.chromaprint.overrideAttrs (_old: {
    doCheck = false;
  });
}
