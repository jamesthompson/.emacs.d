(require 'go-mode)
(require 'go-eldoc)
(require 'company)
(require 'company-go)
(require 'rainbow-delimiters)

(setq company-idle-delay 0.1)
(setq gofmt-command "goimports")

(global-set-key (kbd "C-c M-n") 'company-complete)
(global-set-key (kbd "C-c C-e") 'company-complete)

(defun my-go-mode-hook ()
  (local-set-key (kbd "M-.") 'godef-jump))

(set (make-local-variable 'company-backends) '(company-go))

(add-hook 'go-mode-hook 'my-go-mode-hook)
(add-hook 'go-mode-hook 'go-eldoc-setup)
(add-hook 'go-mode-hook 'company-mode)

(add-hook 'go-mode-hook
  (lambda ()
    (add-hook 'before-save-hook 'gofmt-before-save)
    (linum-mode 1)
    (paredit-mode 1)
    (setq tab-width 2)
    (setq indent-tabs-mode 1)))
(provide 'setup-golang)
