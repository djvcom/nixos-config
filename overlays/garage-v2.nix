# Overlay to use Garage v2.x instead of v1.x
# The on-disk data on terminus has been migrated to v2, so v1 must not be used
# Remove this overlay once nixpkgs defaults to garage_2
_: prev: {
  garage = prev.garage_2;
}
