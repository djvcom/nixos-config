# Merge Zscaler cert into system CA bundle
_:

{
  flake.modules.darwin.zscaler =
    { username, ... }:
    {
      security.pki.certificateFiles = [
        /Users/${username}/certs/zscaler.pem
      ];
    };
}
