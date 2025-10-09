# Optional AppArmor Profiles

This directory contains optional AppArmor profile extensions that can be enabled/disabled on demand to grant Claude access to additional directories.

## Purpose

By default, claude-confined restricts Claude's access to:
- The current working directory
- `~/.claude` directory
- Standard system binaries and libraries
- Explicitly allowed paths via `--allow`

However, some tasks require temporary access to configuration directories like `~/.config/emacs` or `~/.config/doom`. These optional profiles provide a safe way to grant that access temporarily.

## Security Model

**Default (Safe)**: Without optional profiles enabled, Claude cannot access your Emacs, Doom, or browser configurations. This prevents accidental modifications or sandbox escapes when integrated with editors.

**Optional (Controlled Risk)**: When you explicitly want Claude to modify configurations (e.g., "help me configure Doom Emacs"), you can enable the appropriate profile, complete your task, then disable it.

## Available Profiles

### `emacs-config`
Grants access to:
- `~/.config/emacs/`
- `~/.config/doom/`
- `~/.emacs.d/`
- `~/.doom.d/`

Use when: You want Claude to help configure Emacs or Doom Emacs.

### `browser-config`
Grants access to:
- `~/.mozilla/` (Firefox)
- `~/.config/google-chrome/` (Chrome)
- `~/.config/chromium/` (Chromium)

Use when: You want Claude to help with browser configuration or extension development.

### `full-config-access`
Grants access to:
- `~/.config/` (all configuration files)

⚠️ **WARNING**: This is very broad and should be used sparingly. Only enable for specific tasks that require it.

## Usage

### List available profiles
```bash
just list-profiles
```

### Check profile status
```bash
just profile-status
```

### Enable a profile
```bash
just enable-profile emacs-config
```

This will:
1. Install the optional profile rules to `/etc/apparmor.d/local/`
2. Update the local override file
3. Reload the AppArmor profile
4. Display a warning reminder

### Disable a profile
```bash
just disable-profile emacs-config
```

This will:
1. Remove the optional profile rules
2. Update the local override file
3. Reload the AppArmor profile

## Best Practices

1. **Enable only when needed**: Don't leave optional profiles enabled permanently
2. **Disable after use**: Run `just disable-profile <name>` when your task is complete
3. **Check status**: Run `just profile-status` to see what's currently enabled
4. **Use specific profiles**: Prefer `emacs-config` over `full-config-access`

## Creating Custom Profiles

You can create your own optional profiles by adding files to this directory:

1. Create a new file in `apparmor/optional/` (e.g., `my-custom-profile`)
2. Add AppArmor rules using the `@HOME@` placeholder for the home directory
3. Add comments explaining what the profile does and when to use it
4. Enable it with `just enable-profile my-custom-profile`

Example:
```apparmor
# Custom profile for my project
# Enable with: just enable-profile my-custom-profile

owner @HOME@/.config/myapp/ r,
owner @HOME@/.config/myapp/** rwlkmix -> &claude-confined-unpriv,
```

## How It Works

The optional profile system uses **two layers** of security:

### Layer 1: Bubblewrap (Filesystem Isolation)

The `claude-confined` wrapper script checks which profiles are enabled and automatically bind-mounts the corresponding directories into the sandbox:

```bash
# If emacs-config is enabled, these directories are bound:
--bind ~/.config/emacs
--bind ~/.config/doom
--bind ~/.emacs.d
--bind ~/.doom.d
```

Without bind-mounting, the directories simply don't exist inside the sandbox, regardless of AppArmor permissions.

### Layer 2: AppArmor (Mandatory Access Control)

The main AppArmor profile (`/etc/apparmor.d/claude-confined`) includes:
```apparmor
include if exists <local/claude-confined-unpriv>
```

When you enable a profile:
1. The profile rules are installed to `/etc/apparmor.d/local/claude-confined-optional-<name>`
2. An include directive is added to `/etc/apparmor.d/local/claude-confined-unpriv`
3. The AppArmor profile is reloaded, activating the new rules
4. The `claude-confined` wrapper detects the enabled profile and adds bwrap bind mounts

When you disable a profile:
1. The include directive is removed
2. The optional profile file is deleted
3. The AppArmor profile is reloaded, deactivating the rules
4. The `claude-confined` wrapper stops adding bwrap bind mounts

### Why Both Layers?

- **Bubblewrap**: Prevents access by not mounting the directories at all (first line of defense)
- **AppArmor**: Enforces access rules even if directories are mounted (second line of defense)

This defense-in-depth approach means both systems must allow access for it to work.
