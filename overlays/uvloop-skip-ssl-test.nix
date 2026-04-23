_: prev:

# Skip a flaky uvloop SSL test on Linux. CPython 3.13.12 changed
# run_in_executor timing (python/cpython#141696), so
# test_create_ssl_server_manual_connection_lost now races against the
# SSL incoming buffer — see upstream MagicStack/uvloop#743.
# nixpkgs already disables this test on Darwin but not Linux.
# Remove once the upstream fix merges and the uvloop version bumps.
{
  python3Packages = prev.python3Packages.override {
    overrides = pyFinal: pyPrev: {
      uvloop = pyPrev.uvloop.overridePythonAttrs (old: {
        disabledTestPaths = (old.disabledTestPaths or [ ]) ++ [
          "tests/test_context.py::Test_UV_Context::test_create_ssl_server_manual_connection_lost"
        ];
      });
    };
  };
}
