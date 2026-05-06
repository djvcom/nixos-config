_: prev:

# kvazaar's test suite shells out to ffmpeg to generate test video data.
# ffmpeg is killed with SIGKILL (exit 137) in the macOS Nix sandbox.
# Disable the test suite on Darwin.
# Remove once nixpkgs skips sandbox-incompatible tests on Darwin.
{
  kvazaar = prev.kvazaar.overrideAttrs (_old: {
    doCheck = false;
  });
}
