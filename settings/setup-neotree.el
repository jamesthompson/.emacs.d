(require 'neotree)

(global-set-key (kbd "C-x n t") 'neotree-toggle)

(setq neo-theme 'ascii)

(setq neo-hidden-regexp-list '("^\\." "\\.cs\\.meta$" "\\.pyc$" "~$" "^#.*#$" "\\.elc$" "\\.agdai"))

(provide 'setup-neotree)
