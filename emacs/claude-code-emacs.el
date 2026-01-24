;;; claude-code-emacs.el --- Emacs configuration for claude-code.el with claude-confined

;; This configuration sets up claude-code.el to use:
;; - vterm as the terminal backend
;; - monet for LSP integration
;; - claude-confined as the executable (sandboxed Claude)

;;; Commentary:

;; Installation Instructions:
;; 1. Add this file to your Emacs configuration directory
;; 2. Load it from your init.el:
;;    (load-file "~/path/to/claude-confined/claude-code-emacs.el")
;; 3. Or copy the relevant sections to your existing configuration
;;
;; Requirements:
;; - Emacs 30.0 or higher
;; - claude-confined installed (run bin/install from claude-confined repo)
;; - MELPA package archive configured

;;; Code:

;; Ensure package.el is initialized
(require 'package)

;; Add MELPA if not already added
(unless (assoc "melpa" package-archives)
  (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t))

(package-initialize)

;; Install and configure required dependencies
(use-package inheritenv
  :vc (:url "https://github.com/purcell/inheritenv" :rev :newest))

;; Install vterm (terminal emulator backend)
(use-package vterm
  :ensure t
  :config
  (setq vterm-max-scrollback 10000))

;; Install monet for LSP integration (optional but recommended)
(use-package monet
  :vc (:url "https://github.com/stevemolitor/monet" :rev :newest)
  :demand t  ; Force monet to load immediately so monet-start-server-function is available
  :config
  (monet-mode 1))

;; Install and configure claude-code.el
(use-package claude-code
  :ensure t
  :vc (:url "https://github.com/stevemolitor/claude-code.el" :rev :newest)

  :custom
  ;; Use vterm as the terminal backend instead of eat
  (claude-code-terminal-backend 'vterm)

  ;; Point to claude-confined executable
  ;; Assumes claude-confined is installed to ~/.local/bin/claude-confined
  ;; Adjust this path if you installed it elsewhere
  (claude-code-program (expand-file-name "~/.local/bin/claude-confined"))

  ;; Optional: Add any command-line switches you want to pass to claude-confined
  ;; Example: (claude-code-program-switches '("--allow" "/extra/path"))
  (claude-code-program-switches nil)

  :config
  ;; Enable claude-code-mode
  (claude-code-mode)

  ;; Integrate with monet for LSP functionality
  ;; This hook ensures monet is set up for each Claude process
  ;; Use with-eval-after-load to ensure monet is fully loaded before adding hook
  (with-eval-after-load 'monet
    (when (fboundp 'monet-start-server-function)
      (add-hook 'claude-code-process-environment-functions
                #'monet-start-server-function)))

  ;; Optional: Set up custom keybindings
  ;; The default is "C-c c" but you can change it here
  :bind-keymap
  ("C-c c" . claude-code-command-map))

;; Optional: Additional configuration for better integration

;; Set up custom notification function (optional)
;; Uncomment if you want custom notifications when Claude finishes tasks
;; (setq claude-code-notification-function
;;       (lambda (msg)
;;         (message "Claude Code: %s" msg)))

;; Verify installation function
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
(message "Run M-x claude-confined-verify-installation to verify setup")

(provide 'claude-code-emacs)
;;; claude-code-emacs.el ends here
