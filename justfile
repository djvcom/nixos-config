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
    nixos-rebuild build --flake .#{{host}}

# Build and switch
rebuild host="terminus":
    sudo nixos-rebuild switch --flake .#{{host}}

# Test configuration (build without activation)
test host="terminus":
    nixos-rebuild test --flake .#{{host}}

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
    sudo nix-collect-garbage -d
