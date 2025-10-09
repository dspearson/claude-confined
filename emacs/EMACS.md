# Emacs Integration for Claude Confined

This document describes how to use `claude-confined` with Emacs via the [`claude-code.el`](https://github.com/stevemolitor/claude-code.el) package.

## Features

- **Sandboxed Claude in Emacs**: Run Claude Code directly in Emacs with all the security benefits of claude-confined
- **vterm backend**: Fast, full-featured terminal emulation
- **monet integration**: LSP integration for better code understanding
- **Custom helpers**: Easy functions to grant additional directory access

## Requirements

- **Emacs 30.0 or higher** (Emacs 29.0+ for Doom Emacs)
- **claude-confined installed**: Run `bin/install` from this repository
- **MELPA configured**: For vanilla Emacs (Doom Emacs handles this automatically)

## Installation

### For Doom Emacs Users

#### 1. Install claude-confined

First, ensure claude-confined is installed:

```bash
cd /path/to/claude-confined
bin/install
```

This installs `claude-confined` to `~/.local/bin/claude-confined`.

#### 2. Add packages to Doom

Add the contents of `doom-packages.el` to your `~/.config/doom/packages.el`:

```elisp
;; claude-code.el with dependencies
(package! inheritenv
  :recipe (:host github :repo "purcell/inheritenv"))

(package! claude-code
  :recipe (:host github :repo "stevemolitor/claude-code.el"))

;; vterm terminal backend
(package! vterm)

;; monet for LSP integration
(package! monet)
```

#### 3. Add configuration to Doom

Add the contents of `doom-config.el` to your `~/.config/doom/config.el`:

```elisp
(use-package! vterm
  :config
  (setq vterm-max-scrollback 10000))

(use-package! monet
  :config
  (monet-mode 1))

(use-package! claude-code
  :config
  (setq claude-code-terminal-backend 'vterm)
  (setq claude-code-program (expand-file-name "~/.local/bin/claude-confined"))
  (setq claude-code-program-switches nil)
  (claude-code-mode)
  (add-hook 'claude-code-process-environment-functions
            #'monet-start-server-function)
  :bind-keymap
  ("C-c c" . claude-code-command-map))

;; Helper functions (optional but recommended)
(defun claude-confined-verify-installation ()
  "Verify that claude-confined is installed and accessible."
  (interactive)
  (let ((claude-path (expand-file-name "~/.local/bin/claude-confined")))
    (if (file-executable-p claude-path)
        (message "✓ claude-confined found at %s" claude-path)
      (error "✗ claude-confined not found at %s" claude-path))))

(defun claude-confined-with-paths (paths)
  "Start Claude Code with additional allowed PATHS."
  (interactive "DAllow directory: ")
  (let* ((paths-list (if (listp paths) paths (list paths)))
         (switches (cl-mapcan (lambda (p) (list "--allow" (expand-file-name p)))
                              paths-list)))
    (let ((claude-code-program-switches switches))
      (call-interactively #'claude-code))))

(defun claude-confined-with-ro-paths (paths)
  "Start Claude Code with read-only access to PATHS."
  (interactive "DRead-only allow directory: ")
  (let* ((paths-list (if (listp paths) paths (list paths)))
         (switches (cl-mapcan (lambda (p) (list "--ro-allow" (expand-file-name p)))
                              paths-list)))
    (let ((claude-code-program-switches switches))
      (call-interactively #'claude-code))))
```

#### 4. Sync Doom packages

Run Doom's sync command:

```bash
doom sync
```

#### 5. Restart Emacs

Restart Emacs or run:

```
M-x doom/reload
```

#### 6. Verify installation

```
M-x claude-confined-verify-installation
```

### For Vanilla Emacs Users

#### 1. Install claude-confined

First, ensure claude-confined is installed:

```bash
cd /path/to/claude-confined
bin/install
```

This installs `claude-confined` to `~/.local/bin/claude-confined`.

#### 2. Load the Emacs configuration

Add to your Emacs init file (`~/.emacs.d/init.el` or `~/.config/emacs/init.el`):

```elisp
;; Load claude-code configuration for claude-confined
(load-file "/path/to/claude-confined/emacs/claude-code-emacs.el")
```

Or if you prefer to manually integrate, copy the relevant sections from `claude-code-emacs.el` into your existing configuration.

#### 3. Restart Emacs

Restart Emacs or evaluate the configuration:

```
M-x eval-buffer
```

#### 4. Verify installation

Run the verification function:

```
M-x claude-confined-verify-installation
```

This checks that `claude-confined` is installed and accessible.

## Usage

### Basic Usage

Press `C-c c` to access Claude Code commands:

- `C-c c c` - Start Claude Code
- `C-c c k` - Kill Claude process
- `C-c c r` - Restart Claude
- `C-c c s` - Switch between Claude buffers

Or run directly:

```
M-x claude-code
```

### Granting Additional Directory Access

Claude Confined automatically grants access to:
- Your current working directory
- `~/.claude/` directory
- Directories added via `--allow` at installation

To temporarily grant access to additional directories:

```elisp
;; Read-write access
M-x claude-confined-with-paths RET /path/to/project RET

;; Read-only access
M-x claude-confined-with-ro-paths RET /path/to/docs RET
```

Or programmatically in your code:

```elisp
;; Grant access to multiple paths
(claude-confined-with-paths '("/home/user/project1" "/home/user/project2"))

;; Read-only access to reference docs
(claude-confined-with-ro-paths '("/usr/share/doc"))
```

### Customisation

The configuration includes several customisable variables:

```elisp
;; Change the executable path (if installed elsewhere)
(setq claude-code-program "/custom/path/to/claude-confined")

;; Add default switches (e.g., always allow a certain directory)
(setq claude-code-program-switches '("--allow" "/home/user/workspace"))

;; Change the keybinding prefix (default is "C-c c")
(use-package claude-code
  :bind-keymap
  ("C-c a" . claude-code-command-map))  ;; Use "C-c a" instead

;; Customize vterm scrollback
(setq vterm-max-scrollback 10000)
```

## Configuration Details

The provided configuration (`claude-code-emacs.el`) sets up:

1. **vterm backend**: Uses vterm instead of eat for better terminal compatibility
2. **monet integration**: LSP server integration via the `monet` package
3. **claude-confined executable**: Points to `~/.local/bin/claude-confined`
4. **Helper functions**: Custom functions for directory access management

## Troubleshooting

### "claude-confined not found"

Ensure claude-confined is installed:

```bash
which claude-confined
# Should output: /home/yourusername/.local/bin/claude-confined
```

If not found, run `bin/install` from the claude-confined repository.

### "Permission denied" errors in Claude

Claude may be trying to access files blocked by the sandbox. Check:

1. **AppArmor logs**: `sudo journalctl -xe | grep -i apparmor | grep claude-confined`
2. **Current directory**: Claude always has access to the directory where you started Emacs
3. **Use --allow**: Grant additional access with `claude-confined-with-paths`

### vterm not loading

Install vterm manually:

```
M-x package-refresh-contents RET
M-x package-install RET vterm RET
```

Ensure you have the required system dependencies:

```bash
# Ubuntu/Debian
sudo apt-get install cmake libtool-bin

# Build vterm module
M-x vterm-module-compile
```

### monet errors

If monet is not available on MELPA or causes issues, you can disable it:

```elisp
;; Comment out monet configuration in claude-code-emacs.el
;; (use-package monet ...)
;; (add-hook 'claude-code-process-environment-functions ...)
```

## Advanced: Optional AppArmor Profiles

If you want Claude to help edit your Emacs configuration, you can temporarily enable the emacs-config profile:

```bash
# Enable Emacs config access
just enable-profile emacs-config

# Use Claude in Emacs to edit configs
# ... make changes ...

# Disable when done
just disable-profile emacs-config
```

**Warning**: Only enable this when you specifically want Claude to edit Emacs configuration files. Keep it disabled otherwise to prevent sandbox escapes.

## Key Bindings Reference

Default keybindings (with `C-c c` prefix):

| Key       | Command                    | Description                |
|-----------|----------------------------|----------------------------|
| `C-c c c` | `claude-code`             | Start Claude Code          |
| `C-c c k` | `claude-code-kill`        | Kill Claude process        |
| `C-c c r` | `claude-code-restart`     | Restart Claude             |
| `C-c c s` | `claude-code-switch`      | Switch Claude buffers      |

Custom functions (no default keybindings):

| Function                         | Description                        |
|----------------------------------|------------------------------------|
| `claude-confined-verify-installation` | Verify claude-confined is installed |
| `claude-confined-with-paths`     | Start with additional --allow paths |
| `claude-confined-with-ro-paths`  | Start with read-only paths         |

## Further Reading

- [`claude-code.el` documentation](https://github.com/stevemolitor/claude-code.el)
- [Claude Confined README](README.md)
- [AppArmor customization](README.md#customization)

## Support

For issues with:
- **claude-confined**: See [claude-confined troubleshooting](README.md#troubleshooting)
- **claude-code.el**: Check the [upstream repository](https://github.com/stevemolitor/claude-code.el/issues)
- **This integration**: Open an issue in the claude-confined repository
