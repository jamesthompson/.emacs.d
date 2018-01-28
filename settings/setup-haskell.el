(require 'haskell-mode)

(require 'rainbow-delimiters)
(add-hook 'haskell-mode-hook #'rainbow-delimiters-mode)

(add-hook 'haskell-mode-hook 'turn-on-haskell-indentation)

(add-hook 'haskell-mode-hook
          (lambda ()
            (linum-mode 1)))

(add-hook 'haskell-mode-hook 'flycheck-pos-tip-mode)

(custom-set-variables
 '(haskell-stylish-on-save t))

(setq haskell-stylish-on-save t)

(require 'hs-lint)
(provide 'setup-haskell)
