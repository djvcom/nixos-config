_: prev: {
  direnv = prev.direnv.override {
    buildGoModule =
      args:
      prev.buildGoModule (
        args
        // {
          CGO_ENABLED = 1;
        }
      );
  };
}
