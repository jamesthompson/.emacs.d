(require 'jsx-mode)

(require 'rainbow-delimiters)

;; Setup jsx-mode
(add-to-list 'auto-mode-alist '("\\.jsx\\'" . jsx-mode))
(autoload 'jsx-mode "jsx-mode" "JSX mode" t)

(add-hook 'jsx-mode-hook #'rainbow-delimiters-mode)

(add-hook 'jsx-mode-hook
          (lambda ()
            (linum-mode 1)))

(provide 'setup-jsx-mode)
