;; init.el -- Single emacs configuration -*- lexical-binding: t; -*-

;; Early sane defaults

;; Garbage collection start up settings
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; Recursion limit
(setq max-lisp-eval-depth 2000)

(setq custom-file "~/.emacs.d/custom.el")
(load custom-file 'noerror)

;; Set path to dependencies
(setq lisps-dir
      (expand-file-name "lisps" user-emacs-directory))

;; Set up load path
(add-to-list 'load-path lisps-dir)

;; Add external projects to load path
(dolist (project (directory-files lisps-dir t "\\w+"))
  (when (file-directory-p project)
    (add-to-list 'load-path project)))

;; Package management

(require 'package)

(defmacro append-to-list (target suffix)
  "Append suffix to target in place"
  `(setq ,target (append ,target ,suffix)))

;; Setup package archives
(append-to-list package-archives
                '(("melpa" . "https://melpa.org/packages/")
                  ("melpa-stable" . "https://stable.melpa.org/packages/")
                  ("org-elpa" . "https://orgmode.org/elpa/")))

(package-initialize)

;; quelpa

(unless (require 'quelpa nil t)
  (with-temp-buffer
    (url-insert-file-contents "https://framagit.org/steckerhalter/quelpa/raw/master/bootstrap.el")
    (eval-buffer)))

;; use-package is the means to configure everything else

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)

(setq use-package-always-ensure t
      use-package-verbose t)



;; Theme(s) & font(s) stuff

(use-package doom-themes
  :config
  (load-theme 'doom-tomorrow-night)
  (doom-themes-visual-bell-config)
  (doom-themes-org-config)
  (custom-theme-set-faces
   'doom-tomorrow-night
   '(font-lock-doc-face ((t (:foreground "#D8D2C1")))         ;; Lighten docstrings
                        magit-diff-added ((,class (:foreground "#D1FA71")))      ;; Proper green for diff deletions
                        magit-diff-removed ((,class (:foreground "#FAB1AB")))))) ;; Proper red for diff deletions



;; Mac-specific defaults

(setq is-mac (equal system-type 'darwin)
      mac-option-modifier 'super
      mac-command-modifier 'meta  ;; Change command to meta
      ns-function-modifier 'hyper
      delete-by-moving-to-trash t ;; Move to trash when deleting stuff
      trash-directory "~/.Trash/emacs"
      ns-pop-up-frames nil)       ;; Don't open files from the workspace in a new frame

(use-package exec-path-from-shell
  :ensure t
  :config
  (exec-path-from-shell-initialize))



;; Sane defaults

(ido-mode t)

;; Variables
(setq ido-enable-prefix nil
      ido-enable-flex-matching t
      ido-case-fold nil
      ido-auto-merge-work-directories-length -1
      ido-create-new-buffer 'always
      ido-use-filename-at-point nil
      ido-max-prospects 25
      locale-coding-system 'utf-8
      backup-directory-alist `(("." . ,(expand-file-name
                                        (concat user-emacs-directory "backups"))))
      vc-make-backup-files t                                   ;; Make backups of files, even when they're in version control
      redisplay-dont-pause t                                   ;; Never defer screen updates when performing operations
      inhibit-startup-message t                                ;; Never want to see startup message
      initial-scratch-message ";; Scratch"                     ;; Scratch header
      global-auto-revert-non-file-buffers t                    ;; Also auto refresh dired, but be quiet about it
      auto-revert-verbose nil
      user-settings-dir (concat user-emacs-directory
                                "/Users/" user-login-name)     ;; Set user settings directory
      vc-make-backup-files t                                   ;; Make backups of files, even when they're in version control
      x-select-enable-clipboard t                              ;; Allow pasting selection outside of Emacs
      visible-bell t
      color-theme-is-global t
      truncate-partial-width-windows nil
      shift-select-mode nil                                    ;; Do not use shift to mark things
      delete-by-moving-to-trash t                              ;; Move files to trash when deleting
      echo-keystrokes 0.1                                      ;; Echo keystrokes fast
      column-number-mode t
      fill-column 80
      history-length 1000
      enable-recursive-minibuffers t                           ;; Allow recursive minibuffers
      org-replace-disputed-keys t                              ;; org-mode: Don't prevent S-arrow to switch windows (use M-+ and M-- instead to toggle)
      electric-indent-mode nil                                 ;; No electric indent
      eval-expression-print-level nil                          ;; Always see what's happening
      whitespace-style '(trailing lines space-before-tab
                                  indentation space-after-tab) ;; Whitespace-style
      whitespace-line-column 80
      dired-dwim-target t                                      ;; Move files between the open split windows
      inhibit-compacting-font-caches t)                        ;; Fix for all-the-icons slow rendering

(add-to-list 'load-path user-settings-dir)

(defun maybe-unset-buffer-modified (&optional _)
  "Clear modified bit on all unmodified buffers."
  (interactive)
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (and buffer-file-name (buffer-modified-p) (current-buffer-matches-file-p))
        (set-buffer-modified-p nil)))))

;; Don't prompt to save unmodified buffers on exit.
(advice-add 'save-buffers-kill-emacs :before #'maybe-unset-buffer-modified)

(if (fboundp 'menu-bar-mode)
    (menu-bar-mode -1))
(if (fboundp 'tool-bar-mode)
    (tool-bar-mode -1))
(if (fboundp 'scroll-bar-mode)
    (scroll-bar-mode -1))

(random t) ;; Seed the random-number generator

;; Answering just 'y' or 'n' is superior to typing three letters
(defalias 'yes-or-no-p 'y-or-n-p)

(set-terminal-coding-system 'utf-8) ;; UTF-8 everywhere by default
(set-keyboard-coding-system 'utf-8) ;; UTF-8 everywhere by default
(set-selection-coding-system 'utf-8) ;; UTF-8 everywhere by default
(prefer-coding-system 'utf-8) ;; UTF-8 everywhere by default
(global-hl-line-mode 1) ;; Highlight current line
(add-hook 'before-save-hook 'delete-trailing-whitespace) ;; Always delete trailing whitespace upon saving
(global-auto-revert-mode 1) ;; Auto refresh buffers
(transient-mark-mode 1) ;; Show active region
(make-variable-buffer-local 'transient-mark-mode)
(put 'transient-mark-mode 'permanent-local t)
(delete-selection-mode 1) ;; Remove text in active region if inserting text
(auto-compression-mode t) ;; Transparently open compressed files
(add-hook 'prog-mode-hook #'display-line-numbers-mode) ;; display line numbers in any prog-mode buffer
(savehist-mode 1) ;; Save minibuffer history
(set-default 'indent-tabs-mode nil) ;; Never insert tabs
(set-default 'indicate-empty-lines nil) ;; Don't show me empty lines after buffer end
(global-subword-mode 1) ;; Easily navigate sillycased words
(show-paren-mode 1) ;; Always highlight matching paren when point is above one

(setq-default transient-mark-mode t
              truncate-lines t) ;; By default truncate lines

;; Create parent directories if they do not exist
;; http://iqbalansari.github.io/blog/2014/12/07/automatically-create-parent-directories-on-visiting-a-new-file-in-emacs/
(defun propose-create-non-existent-directory ()
  (let ((parent-directory (file-name-directory buffer-file-name)))
    (when (and (not (file-exists-p parent-directory))
               (y-or-n-p (format "Directory `%s' does not exist! Create it?" parent-directory)))
      (make-directory parent-directory t))))

(add-to-list 'find-file-not-found-functions 'propose-create-non-existent-directory)
(add-to-list 'ido-ignore-directories "target")
(add-to-list 'ido-ignore-files "\\.DS_Store")

(use-package dash)



;;dired

;; C-a is nicer in dired if it moves back to start of files
(defun dired-back-to-start-of-files ()
  (interactive)
  (backward-char (- (current-column) 2)))

;; M-up is nicer in dired if it moves to the fourth line - the first file
(defun dired-back-to-top ()
  (interactive)
  (beginning-of-buffer)
  (dired-next-line 4))

;; M-down is nicer in dired if it moves to the last file
(defun dired-jump-to-bottom ()
  (interactive)
  (end-of-buffer)
  (dired-next-line -1))

;; Reload dired after making changes
(--each '(dired-do-rename
          dired-do-copy
          dired-create-directory
          wdired-abort-changes)
  (eval `(defadvice ,it (after revert-buffer activate)
           (revert-buffer))))

(eval-after-load "dired"
  '(progn
     (define-key dired-mode-map (kbd "C-a") 'dired-back-to-start-of-files)
     (define-key dired-mode-map (kbd "k") 'dired-do-delete)
     (define-key dired-mode-map (vector 'remap 'beginning-of-buffer) 'dired-back-to-top)
     (define-key dired-mode-map (vector 'remap 'smart-up) 'dired-back-to-top)
     (define-key dired-mode-map (vector 'remap 'end-of-buffer) 'dired-jump-to-bottom)
     (define-key dired-mode-map (vector 'remap 'smart-down) 'dired-jump-to-bottom)
     (define-key dired-mode-map (kbd "C-x C-k") 'dired-do-delete)))

(eval-after-load "wdired"
  '(progn
     (define-key wdired-mode-map (kbd "C-a") 'dired-back-to-start-of-files)
     (define-key wdired-mode-map (vector 'remap 'beginning-of-buffer) 'dired-back-to-top)
     (define-key wdired-mode-map (vector 'remap 'end-of-buffer) 'dired-jump-to-bottom)))

;; Use normal tabs in makefiles
(add-hook 'makefile-mode-hook 'indent-tabs-mode)

;; Set clear buffer for shell
(add-hook 'shell-mode-hook
          '(lambda()
             (local-set-key (kbd "M-k") 'clear-shell)))

;; Paredit for emacs-lisp-mode
(add-hook 'emacs-lisp-mode-hook #'paredit-mode)


;; Global key bindings

;; Perform general cleanup.
(defun untabify-buffer ()
  (interactive)
  (untabify (point-min) (point-max)))

(defun indent-buffer ()
  (interactive)
  (indent-region (point-min) (point-max)))

(defun cleanup-buffer ()
  "Perform a bunch of operations on the whitespace content of a buffer.
   Including indent-buffer, which should not be called automatically on save."
  (interactive)
  (untabify-buffer)
  (delete-trailing-whitespace)
  (indent-buffer))

;; Window switching (between horizontal / vertical)
(defun toggle-window-split ()
  (interactive)
  (if (= (count-windows) 2)
      (let* ((this-win-buffer (window-buffer))
             (next-win-buffer (window-buffer (next-window)))
             (this-win-edges (window-edges (selected-window)))
             (next-win-edges (window-edges (next-window)))
             (this-win-2nd (not (and (<= (car this-win-edges)
                                         (car next-win-edges))
                                     (<= (cadr this-win-edges)
                                         (cadr next-win-edges)))))
             (splitter
              (if (= (car this-win-edges)
                     (car (window-edges (next-window))))
                  'split-window-horizontally
                'split-window-vertically)))
        (delete-other-windows)
        (let ((first-win (selected-window)))
          (funcall splitter)
          (if this-win-2nd (other-window 1))
          (set-window-buffer (selected-window) this-win-buffer)
          (set-window-buffer (next-window) next-win-buffer)
          (select-window first-win)
          (if this-win-2nd (other-window 1))))))

;; Like isearch, but adds region (if any) to history and deactivates mark
(defun isearch-forward-use-region ()
  (interactive)
  (when (region-active-p)
    (add-to-history 'search-ring (region-as-string))
    (deactivate-mark))
  (call-interactively 'isearch-forward))
(global-set-key (kbd "C-s") 'isearch-forward-use-region)

(defun isearch-backward-use-region ()
  (interactive)
  (when (region-active-p)
    (add-to-history 'search-ring (region-as-string))
    (deactivate-mark))
  (call-interactively 'isearch-backward))

;; Create scratch buffer
(defun create-scratch-buffer nil
  "create a new scratch buffer to work in. (could be *scratch* - *scratchX*)"
  (interactive)
  (let ((n 0)
        bufname)
    (while (progn
             (setq bufname (concat "*scratch"
                                   (if (= n 0) "" (int-to-string n))
                                   "*"))
             (setq n (1+ n))
             (get-buffer bufname)))
    (switch-to-buffer (get-buffer-create bufname))
    (emacs-lisp-mode)
    ))

;; Buffer file functions
(defun touch-buffer-file ()
  (interactive)
  (insert " ")
  (backward-delete-char 1)
  (save-buffer))

(defun rename-current-buffer-file ()
  "Renames current buffer and file it is visiting."
  (interactive)
  (let ((name (buffer-name))
        (filename (buffer-file-name)))
    (if (not (and filename (file-exists-p filename)))
        (error "Buffer '%s' is not visiting a file!" name)
      (let ((new-name (read-file-name "New name: " filename)))
        (if (get-buffer new-name)
            (error "A buffer named '%s' already exists!" new-name)
          (rename-file filename new-name 1)
          (rename-buffer new-name)
          (set-visited-file-name new-name)
          (set-buffer-modified-p nil)
          (message "File '%s' successfully renamed to '%s'"
                   name (file-name-nondirectory new-name)))))))

(define-key key-translation-map [?\C-h] [?\C-?])

;; toggle two most recent buffers
(fset 'quick-switch-buffer [?\C-x ?b return])

;; Shift+direction
(windmove-default-keybindings)

(global-set-key (kbd "C-x -") 'toggle-window-split)
(global-set-key (kbd "C-x r q") 'save-buffers-kill-terminal) ;; Kill emacs `C-x REALLY QUIT`
(global-set-key (kbd "C-x C-c") 'delete-frame)
(global-set-key (kbd "M-x") 'smex)                           ;; Smart M-x
(global-set-key (kbd "M-X") 'smex-major-mode-commands)
(global-set-key (kbd "C-c n") 'cleanup-buffer)
(global-set-key (kbd "C-H") 'help-command)                   ;; Use shell-like backspace C-h, rebind help to C-H
(global-set-key (kbd "M-h") 'kill-region-or-backward-word)
(global-set-key (kbd "M-SPC") 'cycle-spacing)                ;; Manipulate whitespace
(global-set-key (kbd "C-r") 'isearch-backward-use-region)
(global-set-key (kbd "C-S-s") 'isearch-forward)              ;; Like isearch-*-use-region, but doesn't screw with the active region
(global-set-key (kbd "C-S-r") 'isearch-backward)
(global-set-key (kbd "H-*") 'beginning-of-buffer)            ;; Rapid buffer top / bottom navigation
(global-set-key (kbd "H-n") 'end-of-buffer)
(global-set-key (kbd "M-&") 'query-replace-regexp)           ;; Query replace regex key binding
(global-set-key (kbd "C-c c") 'comment-or-uncomment-region)  ;; Comment/uncomment block
(global-set-key (kbd "C-c u") 'uncomment-region)
(global-set-key (kbd "C-c C-k") 'eval-buffer)                ;; Eval buffer
(global-set-key (kbd "C-c b") 'create-scratch-buffer)
(global-set-key (kbd "M-p") 'backward-paragraph)             ;; Paragraph navigation
(global-set-key (kbd "M-n") 'forward-paragraph)              ;; Paragraph navigation
(global-set-key (kbd "<s-right>") 'windmove-right)           ;; Move windows, even in org-mode
(global-set-key (kbd "<s-left>") 'windmove-left)
(global-set-key (kbd "<s-up>") 'windmove-up)
(global-set-key (kbd "<s-down>") 'windmove-down)
(global-set-key (kbd "M-s l") 'sort-lines)                   ;; Sorting
(global-set-key (kbd "M-s p") 'sort-paragraphs)              ;; Sorting
(global-set-key (kbd "C-x t") 'touch-buffer-file)
(global-set-key (kbd "C-x C-r") 'rename-current-buffer-file)
(autoload 'dired-jump "dired")
(global-set-key (kbd "C-x C-j") 'dired-jump)                 ;; Jump from file to containing directory



;; Find file in project (ffip)

(use-package find-file-in-project)

;; No need to be stingy
(setq ffip-limit 4096)

;; Use full project path for ffip

(defun ffip-project-files ()
  "Return an alist of all filenames in the project and their path."
  (let ((file-alist nil))
    (mapcar (lambda (file)
              (let ((file-cons (cons (s-chop-prefix (file-truename (ffip-project-root)) (expand-file-name file))
                                     (expand-file-name file))))
                (add-to-list 'file-alist file-cons)
                file-cons))
            (split-string (shell-command-to-string
                           (format "find %s -type f \\( %s \\) %s | head -n %s"
                                   (or ffip-project-root
                                       (ffip-project-root)
                                       (error "No project root found"))
                                   (ffip-join-patterns)
                                   ffip-find-options
                                   ffip-limit))))))

;; Helper methods to create local settings

(defun ffip--create-exclude-find-options (names)
  (mapconcat (lambda (name)
               (concat "-not -regex \".*" name ".*\"")) names " "))

(defun ffip-local-excludes (&rest names)
  "Given a set of names, will exclude results with those names in the path."
  (set (make-local-variable 'ffip-find-options)
       (ffip--create-exclude-find-options names)))

(defun ffip-local-patterns (&rest patterns)
  "An exhaustive list of file name patterns to look for."
  (set (make-local-variable 'ffip-patterns) patterns))

;; Function to create new functions that look for a specific pattern
(defun ffip-create-pattern-file-finder (&rest patterns)
  (lexical-let ((patterns patterns))
               (lambda ()
                 (interactive)
                 (let ((ffip-patterns patterns))
                   (find-file-in-project)))))

;; Default excludes - override with ffip-local-excludes

(setq-default ffip-find-options
              (ffip--create-exclude-find-options
               '("/node_modules"
                 "/bower_components"
                 "/target"
                 "/out"
                 "/overlays"
                 "/build"
                 "/dist"
                 "/vendor"
                 "/.cask"
                 "/generated"
                 "/.repl"
                 "/.tmp"
                 "/.stack-work")))

(global-set-key (kbd "C-x o") 'find-file-in-project)

;; Finding files
(use-package s)

(defvar user-home-directory (concat (expand-file-name "~") "/"))

(defun shorter-file-name (file-name)
  (s-chop-prefix user-home-directory file-name))

(defun recentf--file-cons (file-name)
  (cons (shorter-file-name file-name) file-name))

;; recentf
(use-package recentf
  :init (recentf-mode t)
  :config
  (add-to-list 'recentf-exclude "\\.emacs.d")
  (add-to-list 'recentf-exclude ".+tmp......\\.org"))

(defun recentf-ido-find-file ()
  "Find a recent file using ido."
  (interactive)
  (let* ((recent-files (mapcar 'recentf--file-cons recentf-list))
         (files (mapcar 'car recent-files))
         (file (completing-read "Choose recent file: " files)))
    (find-file (cdr (assoc file recent-files)))))
(global-set-key (kbd "C-x f") 'recentf-ido-find-file)



;; Number hacks

(defun increment-number-at-point ()
  (interactive)
  (skip-chars-backward "0123456789")
  (or (looking-at "[0123456789]+")
      (error "No number at point"))
  (replace-match (number-to-string (1+ (string-to-number (match-string 0))))))
(global-set-key (kbd "C-c +") 'increment-number-at-point)

(defun decrement-number-at-point ()
  (interactive)
  (skip-chars-backward "0123456789")
  (or (looking-at "[0123456789]+")
      (error "No number at point"))
  (replace-match (number-to-string (- (string-to-number (match-string 0)) 1))))
(global-set-key (kbd "C-c -") 'decrement-number-at-point)


;; Indent region (n.b. C-x TAB <left> <right> for interative indentation)
(global-set-key (kbd "C-i") 'indent-region)


;; Automagic word completion
(global-set-key (kbd "C-c E") 'hippie-expand-no-case-fold)


;; Package loading / setup

(use-package direnv
  :config
  (direnv-mode))

(use-package quelpa-use-package)

(use-package paredit)

;; Modeline uncluttering
(use-package diminish
  :ensure t)

(diminish 'eldoc-mode)
(diminish 'paredit-mode)
(diminish 'elisp-slime-nav)
(diminish 'smartparens-mode)
(diminish 'guide-key-mode)
(diminish 'whitespace-cleanup-mode)
(diminish 'subword-mode)

(use-package all-the-icons)

(use-package doom-modeline
  :ensure t
  :init
  :hook (after-init . doom-modeline-mode)
  :config
  (doom-modeline-def-modeline 'plain-modeline
    '(bar major-mode matches buffer-info vcs buffer-position parrot selection-info)
    '(misc-info minor-modes input-method buffer-encoding process checker))
  (setq doom-modeline-height 32
        doom-modeline-bar-width 6
        doom-modeline-minor-modes t
        doom-modeline-buffer-file-name-style 'truncate-upto-project
        doom-modeline-vcs-max-length 32
        doom-modeline-indent-info t)
  (when window-system
      (setq doom-modeline-icon t
            doom-modeline-major-mode-icon t
            doom-modeline-major-mode-color-icon t))
  (doom-modeline-set-modeline 'plain-modeline 'default))

;; ido stuff
(use-package flx-ido
  :init (flx-ido-mode 1))

(use-package ido-vertical-mode
  :init (ido-vertical-mode))

(use-package ido-at-point
  :init (ido-at-point-mode))

(use-package ido-completing-read+
  :init (ido-ubiquitous-mode 1))

(defun sd/ido-define-keys ()
  (define-key ido-completion-map (kbd "C-n") 'ido-next-match)
  (define-key ido-completion-map (kbd "<down>") 'ido-next-match)
  (define-key ido-completion-map (kbd "C-p") 'ido-prev-match)
  (define-key ido-completion-map (kbd "<up>") 'ido-prev-match))

;; smex
(use-package smex)

;; Rainbow delimiters
(use-package rainbow-delimiters
  :hook ((prog-mode . rainbow-delimiters-mode)))

;; Expand region intelligently
(use-package expand-region
  :bind (("C-c n" . er/expand-region)))

;; Deadgrep (ripgrep (rg) within emacs)
(use-package spinner
  :ensure f
  :pin manual)

(use-package spinner
  :load-path "lisps/spinner")

(use-package deadgrep
  :bind (("C-c G" . deadgrep)))

;; Magit
(use-package magit
  :bind ("C-x m" . magit-status)
  :diminish magit-auto-revert-mode
  :diminish auto-revert-mode
  :custom
  (magit-remote-set-if-missing t)
  (magit-diff-refine-hun t)
  :config
  (magit-auto-revert-mode t)
  (advice-add 'magit-refresh :before #'maybe-unset-buffer-modified)
  (advice-add 'magit-commit  :before #'maybe-unset-buffer-modified)
  (add-to-list 'magit-no-confirm 'stage-all-changes)
  (set-default 'magit-push-always-verify nil)
  (set-default 'magit-revert-buffers 'silent)
  (set-default 'magit-no-confirm '(stage-all-changes
                                   unstage-all-changes)))

(use-package git-gutter
  :ensure t
  :init
  (global-git-gutter-mode +1))

;; flycheck

(use-package flycheck
  :commands (flycheck-mode
             flycheck-next-error
             flycheck-previous-error)
  :init
  :config
  (defalias 'show-error-at-point-soon
    'flycheck-show-error-at-point)

  (defun adjust-flycheck-automatic-syntax-eagerness ()
    "Adjusts how often error checking runs based on error quantity.
     i.e. Fixes errors as quickly as possible, but in a
     clean buffer error checking is much less frequent."
    (setq flycheck-idle-change-delay
          (if flycheck-current-errors 0.5 30.0)))

  (defun flycheck-handle-idle-change ()
    "Handle an expired idle time since the last change.
     Overwritten version of the original flycheck-handle-idle-change,
     which removes the forced deferred.
     Timers should only trigger inbetween commands in a single
     threaded system and the forced deferred makes errors never show
     up before you execute another command."
    (flycheck-clear-idle-change-timer)
    (flycheck-buffer-automatically 'idle-change))

  ;; Each buffer gets its own idle-change-delay because of the
  ;; buffer-sensitive adjustment above.
  (make-variable-buffer-local 'flycheck-idle-change-delay)

  (add-hook 'flycheck-after-syntax-check-hook
            'adjust-flycheck-automatic-syntax-eagerness)

  ;; Remove newline checks, since they would trigger an immediate check
  ;; when we want the idle-change-delay to be in effect while editing.
  (setq-default flycheck-check-syntax-automatically '(save
                                                      idle-change
                                                      mode-enabled)))

;; Company

(use-package company
  :bind (("C-c e" . company-complete))
  :diminish company-mode
  :custom
  (company-dabbrev-downcase nil)
  (company-show-numbers t)
  (company-tooltip-limit 10)
  (company-abort-manual-when-too-short t)
  :config
  (global-company-mode)
  (setq company-idle-delay 0.2)
  ;; use numbers 0-9 to select company completion candidates
  (let ((map company-active-map))
    (mapc (lambda (x) (define-key map (format "%d" x)
                        `(lambda () (interactive) (company-complete-number ,x))))
          (number-sequence 0 9))))

;; Haskell

(use-package haskell-mode
  :mode ("\\.hs$" . haskell-mode)
  :config
  (setq haskell-stylish-on-save t)
  (add-hook 'haskell-mode-hook 'turn-on-haskell-indentation))


;; Protobuf

(use-package protobuf-mode
  :ensure t
  :init
  :config
  (c-add-style "pb style"
               '((c-basic-offset . 2)
                 (indent-tabs-mode . nil))))

;; JSON

(use-package json-mode
  :mode "\\.json\\'")

(use-package yaml-mode)

;; Nix

(use-package nix-mode
  :mode "\\.nix\\'")

;; Dhall

(use-package dhall-mode
  :init
  :config
  (setq dhall-format-at-save nil))

;; ATS2

(use-package ats-mode
  :load-path "lisps/ats-mode"
  :init
  (add-to-list 'auto-mode-alist '("\\.hats$" . ats-mode))
  (add-to-list 'auto-mode-alist '("\\.cats$" . ats-mode))
  (add-to-list 'auto-mode-alist '("\\.dats$" . ats-mode))
  (add-to-list 'auto-mode-alist '("\\.sats$" . ats-mode))
  (add-to-list 'auto-mode-alist '("\\.pats$" . ats-mode)))

;; JVM Stuff

(use-package kotlin-mode)

(use-package gradle-mode)

(use-package groovy-mode
  :init
  (add-to-list 'auto-mode-alist '("\\.gradle$" . groovy-mode)))

;; Build Tools

(use-package dockerfile-mode)

(use-package bazel-mode)


;; Sundry other stuff

(use-package string-inflection)


;; Package setup end

;; Garbage collection settings
(setq gc-cons-threshold 16777216
      gc-cons-percentage 0.1)

(defun defer-garbage-collection ()
  (setq gc-cons-threshold most-positive-fixnum))

(defun restore-garbage-collection ()
  ;; Defer it so that commands launched immediately after will enjoy the
  ;; benefits.
  (run-at-time
   1 nil (lambda () (setq gc-cons-threshold 16777216))))

(add-hook 'minibuffer-setup-hook #'defer-garbage-collection)
(add-hook 'minibuffer-exit-hook #'restore-garbage-collection)

(provide 'init)

;;; init.el ends here
