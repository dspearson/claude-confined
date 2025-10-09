;;; doom-packages.el --- Doom Emacs package configuration for claude-code.el

;; Add this to your ~/.config/doom/packages.el file

;;; Commentary:

;; This configures the required packages for claude-code.el with vterm and monet

;;; Code:

;; claude-code.el with dependencies
(package! inheritenv
  :recipe (:host github :repo "purcell/inheritenv"))

(package! claude-code
  :recipe (:host github :repo "stevemolitor/claude-code.el"))

;; vterm terminal backend
(package! vterm)

;; monet for LSP integration
(package! monet)

;;; doom-packages.el ends here
