(require 'anaconda-mode)
(require 'rainbow-delimiters)

(add-hook 'python-mode-hook #'anaconda-mode)
(add-hook 'python-mode-hook #'rainbow-delimiters-mode)

(add-hook 'python-mode-hook
          (lambda ()
            (linum-mode 1)))

(provide 'setup-python)
