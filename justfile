# Format all Nix files
fmt:
    find . -name "*.nix" -type f -exec nixfmt {} \;

# Run linters (statix + deadnix)
lint:
    statix check .
    deadnix .

# Format and lint
check: fmt lint

# Build without switching
build host="terminus":
    nh os build . -H {{host}}

# Build and switch
rebuild host="terminus":
    nh os switch . -H {{host}}

# Test configuration (build without activation)
test host="terminus":
    nh os test . -H {{host}}

# Run pre-flight check
preflight:
    sudo systemctl start nixos-upgrade-preflight

# Show flake outputs
show:
    nix flake show

# Update flake inputs
update:
    nix flake update

# Garbage collect old generations
clean:
    nh clean all --keep-since 7d --keep 3
