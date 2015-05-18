(require 'haskell-mode)
(require 'ghc)

(add-hook 'haskell-mode-hook 'turn-on-haskell-indentation)

(add-hook 'haskell-mode-hook
          (lambda ()
            (linum-mode 1)))


(setq ghc-debug t)
(autoload 'ghc-init "ghc" nil t)
(autoload 'ghc-debug "ghc" nil t)
(add-hook 'haskell-mode-hook (lambda () (ghc-init)))

(provide 'setup-haskell)
