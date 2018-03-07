(require 'nix-mode)

(add-hook 'nix-mode-hook
          (lambda ()
            (linum-mode 1)))

(provide 'setup-nix)
