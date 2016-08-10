(require 'swift-mode)
(require 'flycheck)

(add-hook 'swift-mode-hook
          '(lambda ()
             (yas/minor-mode-on)))

(add-hook 'before-save-hook 'delete-trailing-whitespace)

(add-hook 'swift-mode-hook
          (lambda ()
            (linum-mode 1)))

(add-to-list 'flycheck-checkers 'swift)

(add-hook 'swift-mode-hook
          (lambda () (setq dash-at-point-docset "swift")))

(provide 'setup-swift)
