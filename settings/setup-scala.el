(add-hook 'scala-mode-hook
          '(lambda ()
             (yas/minor-mode-on)))

(add-hook 'before-save-hook 'delete-trailing-whitespace)

(add-hook 'scala-mode-hook
          (lambda ()
            (linum-mode 1)))

(add-hook 'scala-mode-hook
          (lambda () (setq dash-at-point-docset "scala")))

(provide 'setup-scala)
