;;; doom-config.el --- Doom Emacs configuration for claude-code.el with claude-confined

;; Add this to your ~/.config/doom/config.el file

;;; Commentary:

;; This configures claude-code.el to use:
;; - vterm as the terminal backend
;; - monet for LSP integration
;; - claude-confined as the sandboxed executable

;;; Code:

(use-package! vterm
  :config
  (setq vterm-max-scrollback 10000))

(use-package! monet
  :config
  (monet-mode 1))

(use-package! claude-code
  :config
  ;; Use vterm as the terminal backend
  (setq claude-code-terminal-backend 'vterm)

  ;; Point to claude-confined executable
  ;; Assumes claude-confined is installed to ~/.local/bin/claude-confined
  (setq claude-code-program (expand-file-name "~/.local/bin/claude-confined"))

  ;; Optional: Add default command-line switches
  ;; Example: (setq claude-code-program-switches '("--allow" "/extra/path"))
  (setq claude-code-program-switches nil)

  ;; Enable claude-code-mode
  (claude-code-mode)

  ;; Integrate with monet for LSP functionality
  (add-hook 'claude-code-process-environment-functions
            #'monet-start-server-function)

  ;; Set up keybindings (default: C-c c)
  :bind-keymap
  ("C-c c" . claude-code-command-map))

;; Helper function to verify installation
(defun claude-confined-verify-installation ()
  "Verify that claude-confined is installed and accessible."
  (interactive)
  (let ((claude-path (expand-file-name "~/.local/bin/claude-confined")))
    (if (file-executable-p claude-path)
        (message "✓ claude-confined found at %s" claude-path)
      (error "✗ claude-confined not found at %s. Please run bin/install first." claude-path))))

;; Helper function to run claude-confined with additional --allow paths
(defun claude-confined-with-paths (paths)
  "Start Claude Code with additional allowed PATHS.
PATHS should be a list of directory paths to grant access to."
  (interactive "DAllow directory: ")
  (let* ((paths-list (if (listp paths) paths (list paths)))
         (switches (cl-mapcan (lambda (p) (list "--allow" (expand-file-name p)))
                              paths-list)))
    (let ((claude-code-program-switches switches))
      (call-interactively #'claude-code))))

;; Helper function to run claude-confined with read-only paths
(defun claude-confined-with-ro-paths (paths)
  "Start Claude Code with read-only access to PATHS.
PATHS should be a list of directory paths to grant read-only access to."
  (interactive "DRead-only allow directory: ")
  (let* ((paths-list (if (listp paths) paths (list paths)))
         (switches (cl-mapcan (lambda (p) (list "--ro-allow" (expand-file-name p)))
                              paths-list)))
    (let ((claude-code-program-switches switches))
      (call-interactively #'claude-code))))

;; Display helpful message on load
(message "Claude Code configured with claude-confined, vterm backend, and monet!")
(message "Press C-c c to access Claude Code commands")

;;; doom-config.el ends here
