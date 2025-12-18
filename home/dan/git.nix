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
    };
  };
}
