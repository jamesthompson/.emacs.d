(add-hook 'scala-mode-hook
          '(lambda ()
             (yas/minor-mode-on)))

(add-hook 'scala-mode-hook
          (lambda ()
            (linum-mode 1)))

(provide 'setup-scala)
