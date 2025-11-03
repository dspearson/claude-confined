<div align="center">

# Claude Confined

<img src=".claude-confined.png" alt="Claude Confined Logo"/>

Take back control.

</div>

## Overview

Run Claude Code in a sandboxed environment using bubblewrap, AppArmor, and seccomp filters to restrict filesystem access, prevent credential leakage, and limit system capabilities.

**Security layers:**
- **Bubblewrap** - User namespace containerization and filesystem isolation
- **AppArmor** - Mandatory Access Control (MAC) with explicit deny rules for sensitive files
- **Seccomp** - Berkeley Packet Filter (BPF) syscall filtering

## Requirements

### Required

- **bubblewrap** (bwrap) - Containerization and namespace isolation
  - Debian/Ubuntu: `sudo apt-get install bubblewrap`
  - Fedora/RHEL: `sudo dnf install bubblewrap`
  - Arch: `sudo pacman -S bubblewrap`

- **AppArmor** - Mandatory Access Control
  - Usually pre-installed on Ubuntu/Debian
  - Check status: `sudo aa-status`
  - Install: `sudo apt-get install apparmor apparmor-utils`

- **gcc** and **libseccomp-dev** - For compiling seccomp filters
  - Debian/Ubuntu: `sudo apt-get install gcc libseccomp-dev`
  - Fedora/RHEL: `sudo dnf install gcc libseccomp-devel`
  - Arch: `sudo pacman -S gcc libseccomp`

### Auto-installed if missing

The installer will automatically install these if they're not found:

- **bun** - JavaScript runtime (installed via official installer)
- **Claude Code** - Installed via `bun install -g @anthropic-ai/claude-code`

## Installation

```bash
# Basic installation (installs to ~/.local/bin)
bin/install

# Installation with permanently allowed directories
# (adds directories to AppArmor profile for persistent access)
bin/install --allow /home/user/projects --allow /workspace

# View all installation options
bin/install --help
```

**Important notes:**
- Do NOT run with `sudo` - the installer uses sudo internally when needed
- Installation requires sudo access for AppArmor profile deployment
- The installer is interactive and checks all requirements
- Bun and Claude Code will be installed automatically if missing

**Post-installation:**

Ensure `~/.local/bin` is in your PATH:

```bash
export PATH="${HOME}/.local/bin:${PATH}"
```

Add this to your `~/.bashrc` or `~/.zshrc` to make it permanent.

## Usage

### Basic Usage

```bash
# Run Claude Code in sandboxed environment
claude-confined

# Pass arguments to Claude normally
claude-confined chat

# The current working directory is automatically accessible
cd ~/my-project
claude-confined
```

### Runtime Directory Access

Add additional directories at runtime (temporary, not saved to AppArmor profile):

```bash
# Allow read-write access to additional paths
claude-confined --allow /path/to/project

# Allow read-only access
claude-confined --ro-allow /path/to/docs

# Multiple paths
claude-confined --allow /home/user/project1 --ro-allow /usr/share/docs

# Combine with Claude arguments
claude-confined --allow /path/to/project chat
```

**Installation vs Runtime `--allow` flags:**

- **Installation time** (`bin/install --allow PATH`): Permanently adds directory to AppArmor profile
- **Runtime** (`claude-confined --allow PATH`): Temporarily grants access for that execution only

### Debug Mode

Inspect the sandbox environment:

```bash
# Run arbitrary command inside sandbox
claude-confined --bash "ls -la ~"
claude-confined --bash "env"
claude-confined --bash "cat /proc/self/status"
```

### Environment Variables

```bash
# Skip permission checks (use with caution)
DANGEROUSLY_SKIP_PERMISSIONS=1 claude-confined
```

## Claude-Flow Integration

Claude-confined includes first-class support for [claude-flow](https://github.com/ruvnet/claude-flow), an AI orchestration platform with swarm intelligence and persistent memory.

**What's included:**
- `~/.swarm/` - Cross-project memory and AgentDB storage (bind-mounted by default)
- `~/.claude-flow/` - Configuration and state (bind-mounted by default)
- `~/.hive-mind/` - Hive-mind session persistence (bind-mounted by default)

**Quick start:**

```bash
# Install claude-flow globally
bun install -g claude-flow@alpha

# Add claude-flow MCP server (for use within Claude)
claude mcp add claude-flow claude-flow mcp start

# Method 1: Use claude-flow CLI directly (sandboxed)
cd ~/my-project
claude-confined --flow --version
claude-confined --flow memory store api_key "REST endpoints" --namespace backend
claude-confined --flow memory query "API" --namespace backend
claude-confined --flow swarm "build authentication" --claude

# Method 2: Use within Claude Code (memory persists across all projects!)
cd ~/my-project
claude-confined

# Within Claude:
# "Store this API design in memory"
# "Use the hive-mind to coordinate multiple agents"
```

## Emacs Integration

Use `claude-confined` directly in Emacs with [`claude-code.el`](https://github.com/stevemolitor/claude-code.el):

**For Doom Emacs:**
```bash
# Add doom-packages.el to ~/.config/doom/packages.el
# Add doom-config.el to ~/.config/doom/config.el
doom sync
```

**For Vanilla Emacs:**
```elisp
;; Add to your Emacs init file
(load-file "/path/to/claude-confined/claude-code-emacs.el")
```

Features:
- **vterm backend** for fast terminal emulation
- **monet integration** for LSP functionality
- **Sandboxed execution** with all claude-confined security features
- Helper functions to grant additional directory access

See [emacs/EMACS.md](emacs/EMACS.md) for complete installation and usage instructions.

## Security Model

### Filesystem Access

**Allowed by default:**

- **Current working directory** - Full read/write access
- **`~/.claude/`** - Full read/write (Claude state, temporary files, logs)
- **`~/.config/claude/`** - Read/write (Claude configuration)
- **`~/.claude/ssh/`** - Mapped to `~/.ssh` inside sandbox (if directory exists)
- **`~/.swarm/`** - Read/write (claude-flow memory and AgentDB storage)
- **`~/.claude-flow/`** - Read/write (claude-flow configuration and state)
- **`~/.hive-mind/`** - Read/write (claude-flow hive-mind sessions)
- **System binaries** - Read/execute only (`/usr`, `/bin`, `/lib`, etc.)
- **Nix store** - Read/execute only (if `/nix` exists)
- **Additional paths** - Via `--allow` or `--ro-allow` flags

**Explicitly denied:**

- **`~/.ssh/`** - SSH keys (host directory, use `~/.claude/ssh/` instead)
- **`~/.gnupg/`** - GPG keys
- **`~/.aws/`, `~/.docker/`, `~/.kube/`** - Cloud credentials
- **`~/.bash_history`, `~/.zsh_history`** - Shell history files
- **`~/.netrc`, `~/.pypirc`, `~/.npmrc`** - Package manager credentials
- **`~/.cargo/credentials`** - Rust package credentials
- **`/etc/shadow`, `/etc/sudoers`** - System sensitive files
- **`/root/`** - Root user directory

### Process Capabilities

- **Cannot execute** `sudo`, `su`, `mount`, `umount`
- **Cannot access** other users' files
- **Runs in isolated namespaces** (UTS, IPC, user)
- **No dangerous capabilities** inside namespace

### Network Access

- Network is **enabled** to allow Claude to communicate with Anthropic's API
- Uses host network namespace (no network isolation)

### Syscall Filtering

Seccomp BPF filters block dangerous system calls.

## Testing

Run security tests to verify the sandbox:

```bash
# Using just (if installed)
just test

# Or run tests directly (requires claude-confined to be installed)
cd ~/.claude/tmp && cp bin/run-tests . && claude-confined --bash "perl run-tests"
```

Tests verify:
- Sensitive files are blocked (`.gnupg/`, `.aws/`, `/etc/shadow`, etc.)
- Allowed directories are accessible (`.claude/`, current directory)
- Dangerous commands are blocked (`sudo`, `su`)

## Monitoring and Auditing

AppArmor logs all denied operations. Monitor logs to detect issues:

```bash
# View recent AppArmor denials
sudo ausearch -m AVC -ts recent | grep claude-confined

# Or check system journal
sudo journalctl -xe | grep -i apparmor | grep claude-confined

# Or check kernel logs
sudo dmesg | tail -100 | grep -i apparmor
```

## Customisation

### Modifying AppArmor Profile

Edit the profile template and reinstall:

```bash
# Edit the profile
vim apparmor/claude-confined

# Reinstall to apply changes
bin/install
```

The profile uses three layers:
1. **claude-confined** - Outer wrapper profile
2. **claude-confined-bwrap** - Bubblewrap execution profile (with capabilities)
3. **claude-confined-unpriv** - Unprivileged profile for processes inside namespace

### Adding Permanent Directory Access

Add directories to the AppArmor profile permanently:

```bash
bin/install --allow /home/user/projects --allow /workspace
```

This modifies the installed AppArmor profile to grant access to these directories.

### Optional Profiles for Configuration Directories

By default, Claude is restricted from accessing configuration directories like `~/.config/emacs` or `~/.config/doom` to prevent sandbox escapes when integrated with editors. However, you can temporarily enable optional profiles when you specifically want Claude to help with configurations:

```bash
# List available optional profiles
just list-profiles

# Check which profiles are enabled
just profile-status

# Enable a profile (e.g., to let Claude edit your Emacs config)
just enable-profile emacs-config

# Work with Claude on your configuration
claude-confined

# Disable when done
just disable-profile emacs-config
```

**Available optional profiles:**
- **`emacs-config`** - Grants access to Emacs and Doom configuration directories
- **`browser-config`** - Grants access to Firefox/Chrome configuration
- **`full-config-access`** - Grants access to all `~/.config` (use sparingly)

**Best practices:**
- Only enable profiles when you need them
- Disable profiles immediately after completing your task
- Use specific profiles (`emacs-config`) rather than broad ones (`full-config-access`)
- Check `just profile-status` regularly to see what's enabled

See [apparmor/optional/README.md](apparmor/optional/README.md) for details on creating custom optional profiles.

## Uninstallation

```bash
# Uninstall claude-confined
bin/install --uninstall
```

This removes:
- Wrapper script (`~/.local/bin/claude-confined`)
- Seccomp generator (`~/.local/lib/claude-confined/`)
- AppArmor profile (`/etc/apparmor.d/claude-confined`)
- Bun (only if installed by claude-confined installer)

**Not removed:**
- `~/.claude/` directory (your Claude data and SSH keys)
- Claude Code (if installed separately or used by other tools)

## Troubleshooting

### Installation fails with "sudo access required"

The installer needs sudo to install the AppArmor profile. Ensure you have sudo privileges and try again.

### "Error: claude not found in PATH"

Ensure the installer completed successfully and `~/.local/bin` is in your PATH:

```bash
export PATH="${HOME}/.local/bin:${PATH}"
```

### "Operation not permitted" errors

- Check AppArmor status: `sudo aa-status | grep claude-confined`
- Review AppArmor logs: `sudo journalctl -xe | grep -i apparmor`
- Ensure bubblewrap is installed: `which bwrap`

### AppArmor profile not loading

```bash
# Check for syntax errors
sudo apparmor_parser -r /etc/apparmor.d/claude-confined

# View AppArmor logs
sudo dmesg | grep -i apparmor
```

### Claude can't access files

- Ensure you're running from the correct directory (CWD is automatically accessible)
- Use `--allow /path/to/dir` to add additional directories at runtime
- Check file permissions: `ls -la`
- For permanent access, reinstall with `bin/install --allow /path/to/dir`

## How It Works

1. **Wrapper script** (`bin/claude-confined`) sets up the bubblewrap sandbox
2. **Bubblewrap** creates isolated namespaces and bind-mounts filesystem
3. **AppArmor** enforces MAC policy on all processes (three-layer profile)
4. **Seccomp** filters dangerous syscalls (when enabled)
5. **Claude Code** runs inside the sandbox with restricted access

The current directory is bind-mounted into the sandbox, allowing Claude to work on your project files while blocking access to sensitive home directory files.

## Development

### Using direnv

This project includes a `.envrc` file for [direnv](https://direnv.net/) that automatically displays available commands when you enter the directory:

```bash
# Install direnv (if not already installed)
sudo apt-get install direnv

# Add to your shell (~/.bashrc or ~/.zshrc):
eval "$(direnv hook bash)"  # for bash
eval "$(direnv hook zsh)"   # for zsh

# Allow the .envrc in this directory:
direnv allow
```

Now whenever you `cd` into the claude-confined directory, you'll see the available `just` commands automatically.

## Licence

ISC Licence - see [LICENCE](LICENCE) file for details.
