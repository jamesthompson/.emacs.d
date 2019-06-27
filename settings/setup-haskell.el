(require 'haskell-mode)

(require 'rainbow-delimiters)
(add-hook 'haskell-mode-hook #'rainbow-delimiters-mode)

(add-hook 'haskell-mode-hook 'turn-on-haskell-indentation)

(add-hook 'haskell-mode-hook
          (lambda ()
            (display-line-numbers-mode 1)))

(add-hook 'haskell-mode-hook 'flycheck-pos-tip-mode)

(custom-set-variables
 '(haskell-stylish-on-save t))

(setq haskell-stylish-on-save t)

(require 'hs-lint)

(use-package dante
  :ensure t
  :after haskell-mode
  :commands 'dante-mode
  :init
  (add-hook 'haskell-mode-hook 'flycheck-mode)
  (add-hook 'haskell-mode-hook 'dante-mode)
  :config
  (flycheck-add-next-checker 'haskell-dante '(warning . haskell-hlint))
  (add-hook 'haskell-mode-hook 'company-mode))

(setq flymake-no-changes-timeout nil)
(setq flymake-start-syntax-check-on-newline nil)
(setq flycheck-check-syntax-automatically '(save mode-enabled))

(provide 'setup-haskell)
