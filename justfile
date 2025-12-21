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
build:
    nixos-rebuild build --flake .#terminus

# Build and switch
rebuild:
    sudo nixos-rebuild switch --flake .#terminus

# Test configuration (build without activation)
test:
    nixos-rebuild test --flake .#terminus

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
