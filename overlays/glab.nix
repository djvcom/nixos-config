# Overlay to bump glab ahead of nixpkgs
# Remove once nixpkgs provides glab >= 1.107.0
final: prev: {
  glab = prev.glab.overrideAttrs (
    finalAttrs: _old: {
      version = "1.107.0";
      src = final.fetchFromGitLab {
        owner = "gitlab-org";
        repo = "cli";
        tag = "v${finalAttrs.version}";
        hash = "sha256-2Y1ZdKRrwk49N2L/qRaiZM+RUny69KrF5C5dn0Nq8+w=";
        leaveDotGit = true;
        postFetch = ''
          cd "$out"
          git rev-parse --short HEAD > $out/COMMIT
          find "$out" -name .git -print0 | xargs -0 rm -rf
        '';
      };
      vendorHash = "sha256-RtCc8sGlTtUO7SaBP+A4NaPOP62VjHg24CcQNL+TSE0=";
    }
  );
}
