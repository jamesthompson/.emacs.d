(require 'dhall-mode)

(require 'rainbow-delimiters)

(add-hook 'dhall-mode-hook #'rainbow-delimiters-mode)
(add-hook 'dhall-mode-hook
  (lambda () (display-line-numbers-mode 1)))

(add-hook 'dhall-mode-hook
          (lambda () (dhall-format-on-save-mode 0)))

(setq-default indent-tabs-mode nil)
(setq-default tab-width 2)

(provide 'setup-dhall)
