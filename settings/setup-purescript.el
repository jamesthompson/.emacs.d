(require 'purescript-mode)
(require 'rainbow-delimiters)
(require 'psc-ide)

(add-hook 'purescript-mode-hook #'rainbow-delimiters-mode)

(setq psc-ide-use-npm-bin t)

(add-hook 'purescript-mode-hook
  (lambda ()
    (linum-mode 1)
    (psc-ide-mode)
    (company-mode)
    (flycheck-mode)
    (turn-on-purescript-indentation)
    (turn-on-purescript-unicode-input-method)))

(provide 'setup-purescript)
