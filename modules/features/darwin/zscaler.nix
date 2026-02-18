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
