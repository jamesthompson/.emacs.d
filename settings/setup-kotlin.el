(require 'kotlin-mode)
(require 'rainbow-delimiters)
(require 'flycheck-kotlin)

(add-hook 'kotlin-mode-hook #'rainbow-delimiters-mode)

(add-hook 'kotlin-mode-hook #'global-flycheck-mode)

(add-hook 'kotlin-mode-hook
          (lambda ()
            (linum-mode 1)))

(add-hook 'kotlin-mode-hook #'flycheck-kotlin-setup)

(provide 'setup-kotlin)
