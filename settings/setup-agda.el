(require 'rainbow-delimiters)

(load-file (let ((coding-system-for-read 'utf-8))
             (shell-command-to-string "agda-mode locate")))

(require 'agda2)

(autoload 'adga2-mode "adga2-mode"
  "Major mode for editing and type-checking Agda files" t)

(modify-coding-system-alist 'file "\\.l?agda\\'" 'utf-8)

(add-hook 'agda2-mode-hook #'rainbow-delimiters-mode)

(add-hook 'agda2-mode-hook
          (lambda ()
            (linum-mode 1)))

(global-set-key (kbd "C-c t") 'agda2-goal-and-context)

(add-to-list 'ido-ignore-files "\\.agdai")

(provide 'setup-agda)
