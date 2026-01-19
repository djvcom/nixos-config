# Overlay to use Garage v2.x instead of v1.x
# Required for garage-webui which uses the v2 admin API
# Remove this overlay once nixpkgs defaults to garage_2
_: prev: {
  garage = prev.garage_2;
}
