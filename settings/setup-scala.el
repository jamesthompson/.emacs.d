(add-hook 'scala-mode-hook
          '(lambda ()
             (yas/minor-mode-on)))
(yas/load-directory "~/.emacs.d/elpa/yasnippet-20141223.303/snippets/scala-mode/")

(provide 'setup-scala)
