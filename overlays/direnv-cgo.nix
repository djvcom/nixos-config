_: prev: {
  direnv = prev.direnv.overrideAttrs (old: {
    env = (old.env or { }) // {
      CGO_ENABLED = 1;
    };
  });
}
