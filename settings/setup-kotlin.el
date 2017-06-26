(require 'kotlin-mode)

(require 'rainbow-delimiters)
(add-hook 'kotlin-mode-hook #'rainbow-delimiters-mode)

(add-hook 'kotlin-mode-hook
          (lambda ()
            (linum-mode 1)))

(provide 'setup-kotlin)
