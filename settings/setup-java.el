(require 'java-mode)
(require 'rainbow-delimiters)

(add-hook 'haskell-mode-hook #'rainbow-delimiters-mode)

(add-hook 'java-mode-hook
          '(lambda ()
             (yas/minor-mode-on)))

(add-hook 'before-save-hook 'delete-trailing-whitespace)

(add-hook 'java-mode-hook
          (lambda ()
            (linum-mode 1)))

(provide 'setup-java)
