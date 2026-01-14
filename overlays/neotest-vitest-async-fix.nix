# Overlay to fix neotest-vitest async compatibility issue
# The adapter's is_test_file always calls hasVitestDependency which uses
# lib.files.read - an async function that fails in non-async context with nvim-nio.
# This patch allows custom is_test_file to fully bypass the broken check.
# Remove this overlay once nixpkgs updates neotest-vitest with a fix.
_: prev: {
  vimPlugins = prev.vimPlugins // {
    neotest-vitest = prev.vimPlugins.neotest-vitest.overrideAttrs (oldAttrs: {
      postPatch = (oldAttrs.postPatch or "") + ''
            substituteInPlace lua/neotest-vitest/init.lua \
              --replace-fail \
                'adapter.is_test_file = function(file_path)
          return hasVitestDependency(file_path) and opts.is_test_file(file_path)
        end' \
                'adapter.is_test_file = opts.is_test_file'
      '';
    });
  };
}
