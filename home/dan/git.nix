/**
  Git configuration with identity from agenix-managed secret.
*/
_:

{
  programs.git = {
    enable = true;
    includes = [
      {
        path = "~/.config/git/identity";
      }
    ];
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      safe.directory = "/etc/nixos";
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate = true;
        light = false;
        line-numbers = true;
        side-by-side = true;
      };
      merge.conflictStyle = "diff3";
      diff.colorMoved = "default";
    };
  };
}
