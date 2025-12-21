/**
  Git configuration with identity from agenix-managed secret.
*/
{ ... }:

{
  programs.git = {
    enable = true;
    includes = [{
      path = "~/.config/git/identity";
    }];
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      safe.directory = "/etc/nixos";
    };
  };
}
