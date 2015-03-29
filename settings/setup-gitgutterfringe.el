(if (window-system)
    (when (require 'git-gutter-fringe nil t)
      (global-git-gutter-mode +1)
      (setq-default indicate-buffer-boundaries 'left)
      (setq-default indicate-empty-lines +1)))

(set-face-foreground 'git-gutter-fr:modified "yellow")
(set-face-foreground 'git-gutter-fr:added    "gree")
(set-face-foreground 'git-gutter-fr:deleted  "red")

(provide 'setup-git-gutter-fringe)
