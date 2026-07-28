_: prev:

# poetry 2.4.1 has 3 failing tests in test_executor.py on Python 3.14
# due to output format changes. Skip the check phase until nixpkgs
# updates the package or patches the tests.
# Remove once poetry builds cleanly after a future flake update.
{
  poetry = prev.poetry.overridePythonAttrs (_old: {
    doCheck = false;
  });
}
