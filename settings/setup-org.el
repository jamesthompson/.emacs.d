(defun myorg-update-parent-cookie ()
  (when (equal major-mode 'org-mode)
    (save-excursion
      (ignore-errors
        (org-back-to-heading)
        (org-update-parent-todo-statistics)))))

(defadvice org-kill-line (after fix-cookies activate)
  (myorg-update-parent-cookie))

(defadvice kill-whole-line (after fix-cookies activate)
  (myorg-update-parent-cookie))

(org-babel-do-load-languages
 'org-babel-load-languages
 '((dot . t)))

(setq org-directory "~/workspace/org")
(setq org-hide-leading-stars t)
(setq org-startup-indented t)
(setq org-default-notes-file (concat org-directory "/notes.org"))

(define-key global-map (kbd "M-<f6>") 'org-capture)

(add-hook 'org-mode-hook #'org-bullets-mode)

(provide 'setup-org)
