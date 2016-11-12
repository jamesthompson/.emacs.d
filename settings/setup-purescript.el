(require 'purescript-mode)
(require 'rainbow-delimiters)
(require 'psc-ide)

(add-hook 'purescript-mode-hook #'rainbow-delimiters-mode)

(add-hook 'purescript-mode-hook
  (lambda ()
    (linum-mode 1)
    (psc-ide-mode)
    (company-mode)
    (flycheck-mode)
    (turn-on-purescript-indentation)))

(provide 'setup-purescript)
