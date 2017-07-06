(defvar agda2-directory "/usr/local/Cellar/agda/2.5.2/share/x86_64-osx-ghc-8.0.1/Agda-2.5.2/emacs-mode"
  "Path to the directory that contains agda2.el(c).")

(add-to-list 'load-path (or agda2-directory (car load-path)))

(autoload 'agda2-mode "agda2-mode"
  "Major mode for editing Agda files (version ≥ 2)." t)

(add-to-list 'auto-mode-alist '("\\.l?agda\\'" . agda2-mode))
(modify-coding-system-alist 'file "\\.l?agda\\'" 'utf-8)

(provide 'setup-agda)
