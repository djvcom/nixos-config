# Dotfile Migration Todo

Track what's been migrated to nix-darwin and what can be cleaned up.

---

## Disk Cleanup (280GB+ recoverable)

### GOG Galaxy temp files — 84GB
Cached downloads, no games installed.
```bash
rm -rf ~/Library/Application\ Support/GOG.com/Galaxy/\!Temp
```
- [ ] Delete GOG Galaxy temp (84GB)

### Rust build artifacts — 158GB
All `target/` directories, will rebuild on next `cargo build`.
```bash
rm -rf ~/development/lambda-observability/target
rm -rf ~/development/teldb/target
rm -rf ~/development/mock-collector/target
rm -rf ~/development/vernal/target
rm -rf ~/development/_djv-leptops/target
rm -rf ~/development/diagnosi/target
rm -rf ~/development/collector-tester/target
```
- [ ] Delete Rust target directories (158GB)

### Xcode — 18GB
Not using iOS development currently.
```bash
sudo rm -rf ~/Library/Developer/Xcode
sudo rm -rf ~/Library/Developer/Toolchains
sudo rm -rf ~/Library/Developer/CoreSimulator
# Then uninstall Xcode.app from Applications
```
- [ ] Remove Xcode and related files (18GB)

### System caches — 17GB
Safe to delete, apps recreate as needed.
```bash
rm -rf ~/Library/Caches/*
```
- [ ] Clear system caches (17GB)

### Docker cleanup — ~34GB
Run when Docker is running:
```bash
docker system prune -a --volumes
```
- [ ] Prune Docker images/volumes (up to 34GB)

### Steam games (your call)
| Game | Size |
|------|------|
| Pathfinder Wrath of the Righteous | 50GB |
| Stellaris | 28GB |

- [ ] Review Steam games — uninstall via Steam if wanted

---

## Shell Configuration

Files to remove once nix-darwin is working:

- [ ] `~/.bashrc` - replaced by home-manager bash config
- [ ] `~/.profile` - may not be needed
- [ ] `~/.zshrc` - replaced by home-manager zsh config
- [ ] `~/.zshenv` - check if needed
- [ ] `~/.zprofile` - check if needed
- [ ] `~/.oh-my-zsh/` - no longer needed (using zsh plugins via home-manager)
- [ ] `~/.zcompdump*` - zsh completion cache, regenerated automatically
- [ ] `~/.zsh_sessions/` - zsh session data

Old backups (safe to delete):
- [ ] `~/.zshrc.backup`
- [ ] `~/.zshrc.omz-uninstalled-2023-11-13_07-09-08`
- [ ] `~/.zshrc.pre-oh-my-zsh`
- [ ] `~/.codewhisperer.dotfiles.bak/`

## Editor Configuration

- [ ] `~/.config/nvim/` - replaced by home-manager neovim config
- [ ] `~/.viminfo` - vim history, regenerated automatically

## Git Configuration

- [ ] `~/.gitconfig` - replaced by home-manager git config
- [ ] `~/.config/git/` - check contents, may have credentials

## Terminal

- [ ] `~/.tmux.conf` - consider adding to home-manager if you use tmux
- [ ] `~/.config/iterm2/` - iTerm settings (keep if using iTerm)
- [ ] `~/dotfiles/ayu-iTerm/` - old iTerm theme

## Tool Configs (review individually)

These are managed by their respective tools but could potentially be declared in nix:

- [ ] `~/.config/direnv/` - direnv is in home-manager, check if custom config needed
- [ ] `~/.config/gh/` - GitHub CLI auth (keep - contains tokens)
- [ ] `~/.config/glab-cli/` - GitLab CLI auth (keep - contains tokens)
- [ ] `~/.config/fish/` - old fish config if not using fish

## Package Managers (remove after migration)

No longer needed — Node managed by nix, Rust by rustup:

- [ ] `~/.nvm/` - replaced by nix-managed nodejs_24
- [ ] `~/.bun/` - not using
- [ ] `~/google-cloud-sdk/` - not using
- [ ] `~/.fly/` - not using
- [ ] `~/.zig/` - not using
- [ ] `~/.swiftly/` - not using
- [ ] `~/.swiftpm/` - not using
- [ ] `~/go/` - not using Go

Keep:
- `~/.cargo/` - rust packages (used by rustup)
- `~/.rustup/` - rust toolchains

## Cloud/Dev Tool State (keep)

These contain auth tokens or state - don't delete:

- `~/.aws/`
- `~/.azure/`
- `~/.config/gcloud/`
- `~/.kube/`
- `~/.ssh/`
- `~/.docker/`
- `~/.terraform.d/`

## After Migration Checklist

- [x] Nix installed
- [x] nix-darwin bootstrapped
- [x] Shell working correctly (aliases, prompt, completions)
- [x] Git working correctly (with delta for diffs)
- [x] Neovim working correctly (LSP, treesitter, catppuccin theme)
- [x] All tools available (ripgrep, fd, jq, eza, bat, etc.)
- [x] direnv working in project directories
- [x] Ghostty terminal configured
- [x] LibreWolf browser with extensions
- [x] Aerospace tiling window manager
- [x] GitLab token rotation scheduled (Monday 09:00)
- [x] Separate configs for personal/work MacBooks
- [ ] Clean up old dotfiles marked above
- [ ] Set up work MacBook with macbook-work config
