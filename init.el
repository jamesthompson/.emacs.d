;; init.el -- Single emacs configuration -*- lexical-binding: t; -*-

;; Early sane defaults

;; Startup GC settings live in early-init.el; gcmh takes over at the end
;; of this file.

;; Recursion limit
(setq max-lisp-eval-depth 2000)

;; Must be absolute. A relative name resolves against whatever directory
;; Emacs started in, which found Emacs' own custom.el library instead.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
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
(setq package-archives
      '(("melpa" . "https://melpa.org/packages/")
        ("melpa-stable" . "https://stable.melpa.org/packages/")
        ("org-elpa" . "https://orgmode.org/elpa/")
        ("gnu" . "https://elpa.gnu.org/packages/")))
(package-initialize)

(defmacro append-to-list (target suffix)
  "Append suffix to target in place"
  `(setq ,target (append ,target ,suffix)))


;; use-package is the means to configure everything else

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))

;; The deferral variable is use-package-always-defer, not use-package-defer,
;; so the old setting never took effect. It stays nil: UI packages need to
;; load at startup, so language and tool modes carry :defer t individually.
(setq use-package-always-ensure t
      use-package-verbose t)

;; Theme(s) & font(s) stuff
;; You will need to run all-the-icons-install-fonts

(set-face-attribute 'default nil :height 140)

(use-package all-the-icons
  :ensure t)

(use-package doom-themes
  :config
  (load-theme 'doom-tomorrow-night :no-confirm)
  (doom-themes-visual-bell-config)
  (doom-themes-org-config)
  (custom-theme-set-faces
   'doom-tomorrow-night
   '(font-lock-doc-face ((t (:foreground "#D8D2C1")))                            ;; Lighten docstrings
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

;; This daemon starts from launchd, whose PATH is only /usr/bin:/bin:/usr/sbin:/sbin,
;; so the shell environment has to be imported or gopls, cargo and kubectl go
;; missing. The import needs an interactive zsh (the PATH exports live in
;; .zshrc) and that costs about a second, so the result is cached and only
;; recomputed when a shell init file changes. M-x env-cache-refresh forces it.
(use-package exec-path-from-shell
  :ensure t
  :defer t)

(defconst env-cache-file (expand-file-name "env-cache.el" user-emacs-directory))
(defconst env-cache-variables '("PATH" "MANPATH"))
(defconst env-cache-sources '("~/.zshenv" "~/.zprofile" "~/.zshrc"))

(defun env-cache-stale-p ()
  "Non-nil if the cache is missing or older than any shell init file."
  (let ((cached (file-attribute-modification-time
                 (file-attributes env-cache-file))))
    (or (null cached)
        (seq-some (lambda (f)
                    (let ((attrs (file-attributes (expand-file-name f))))
                      (and attrs
                           (time-less-p cached
                                        (file-attribute-modification-time attrs)))))
                  env-cache-sources))))

(defun env-cache-refresh ()
  "Run the login shell, import the environment, and rewrite the cache."
  (interactive)
  (require 'exec-path-from-shell)
  (exec-path-from-shell-copy-envs env-cache-variables)
  (with-temp-file env-cache-file
    (prin1 (mapcar (lambda (v) (cons v (getenv v))) env-cache-variables)
           (current-buffer)))
  (message "Shell environment cached in %s" env-cache-file))

(defun env-cache-load ()
  "Apply the cached shell environment without starting a shell."
  (dolist (pair (with-temp-buffer
                  (insert-file-contents env-cache-file)
                  (read (current-buffer))))
    (when (cdr pair) (setenv (car pair) (cdr pair))))
  (setq exec-path (append (parse-colon-path (getenv "PATH"))
                          (list exec-directory))))

(if (env-cache-stale-p)
    (env-cache-refresh)
  (condition-case nil
      (env-cache-load)
    (error (env-cache-refresh))))

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
      inhibit-startup-message t                                ;; Never want to see startup message
      initial-scratch-message ";; Scratch"                     ;; Scratch header
      global-auto-revert-non-file-buffers t                    ;; Also auto refresh dired, but be quiet about it
      auto-revert-verbose nil
      user-settings-dir (concat user-emacs-directory
                                "/Users/" user-login-name)     ;; Set user settings directory
      vc-make-backup-files nil                                 ;; Git already holds these; writing them again costs a disk write per save
      select-enable-clipboard t                                ;; Allow pasting selection outside of Emacs
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

(set-terminal-coding-system 'utf-8)                      ;; UTF-8 everywhere by default
(set-keyboard-coding-system 'utf-8)                      ;; UTF-8 everywhere by default
(set-selection-coding-system 'utf-8)                     ;; UTF-8 everywhere by default
(prefer-coding-system 'utf-8)                            ;; UTF-8 everywhere by default
(global-hl-line-mode 1)                                  ;; Highlight current line
(add-hook 'before-save-hook 'delete-trailing-whitespace) ;; Always delete trailing whitespace upon saving
(global-auto-revert-mode 1)                              ;; Auto refresh buffers
(transient-mark-mode 1)                                  ;; Show active region
(make-variable-buffer-local 'transient-mark-mode)
(put 'transient-mark-mode 'permanent-local t)
(delete-selection-mode 1)                                ;; Remove text in active region if inserting text
(auto-compression-mode t)                                ;; Transparently open compressed files
(add-hook 'prog-mode-hook #'display-line-numbers-mode)   ;; display line numbers in any prog-mode buffer
(savehist-mode 1)                                        ;; Save minibuffer history
(set-default 'indent-tabs-mode nil)                      ;; Never insert tabs
(set-default 'indicate-empty-lines t)                    ;; Don't show me empty lines after buffer end
(global-subword-mode 1)                                  ;; Easily navigate sillycased words
(show-paren-mode 1)                                      ;; Always highlight matching paren when point is above one

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
          (lambda ()
            (local-set-key (kbd "M-k") 'clear-shell)))

;; Paredit for emacs-lisp-mode
(use-package paredit
  :ensure t
  :hook (emacs-lisp-mode . paredit-mode))

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
(global-set-key (kbd "C-c N") 'cleanup-buffer)               ;; C-c n is expand-region
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
(global-set-key (kbd "C-x g l") 'goto-line)

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
;; Not C-i: in a terminal C-i *is* TAB, so binding it removes TAB everywhere,
;; including indentation, completion-at-point and org cycling.
(global-set-key (kbd "C-c i") 'indent-region)

;; Automagic word completion
(global-set-key (kbd "C-c E") 'hippie-expand-no-case-fold)

;; Package loading / setup

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

;; Scoped to lisp rather than global: it reindents the enclosing block on
;; every change, which is expensive in large Go, TS and JSON buffers.
(use-package aggressive-indent
  :hook ((emacs-lisp-mode lisp-mode scheme-mode) . aggressive-indent-mode)
  :diminish)

(use-package doom-modeline
  :ensure t
  :init
  :hook (after-init . doom-modeline-mode)
  :config
  (doom-modeline-def-modeline 'plain-modeline
    '(bar major-mode matches buffer-info vcs buffer-position parrot selection-info)
    '(misc-info minor-modes input-method buffer-encoding process))
  (setq doom-modeline-height 32
        doom-modeline-bar-width 6
        doom-modeline-minor-modes nil     ;; rendering the full list costs a redisplay pass
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
(use-package smex :defer t)

;; Rainbow delimiters
(use-package rainbow-delimiters :defer t)

(use-package prog-mode
  :ensure nil
  :hook ((prog-mode . rainbow-delimiters-mode)))

;; Expand region intelligently
(use-package expand-region
  :bind (("C-c n" . er/expand-region)))

;; Deadgrep (ripgrep (rg) within emacs)
;; spinner arrives as a dependency. The old declarations pointed :load-path at
;; a directory that does not exist and :ensure at the unrelated package `f',
;; leaving uncompiled lisps/spinner.el shadowing the elpa build.
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
  :ensure t
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

(use-package flyover
  :hook (flycheck-mode . flyover-mode))

;; Company

(use-package company
  ;; :demand because :bind would otherwise defer the package and
  ;; global-company-mode below would not run until C-c e was pressed.
  :demand t
  :bind (("C-c e" . company-complete))
  :diminish company-mode
  :custom
  (company-dabbrev-downcase nil)
  (company-show-numbers t)
  (company-tooltip-limit 10)
  (company-abort-manual-when-too-short t)
  :config
  (global-company-mode)
  ;; A 0 delay with a 1-character prefix queries the backend on every
  ;; keystroke from the first character, which is a lot of LSP round-trips.
  (setq company-idle-delay 0.15
        company-minimum-prefix-length 2)
  ;; use numbers 0-9 to select company completion candidates
  (let ((map company-active-map))
    (mapc (lambda (x) (define-key map (format "%d" x)
                        `(lambda () (interactive) (company-complete-number ,x))))
          (number-sequence 0 9))))

;; Haskell

(use-package haskell-mode
  :mode ("\\.hs$" . haskell-mode)
  :config
  (add-hook 'haskell-mode-hook 'turn-on-haskell-indentation))

;; Protobuf

(use-package protobuf-mode
  :ensure t
  :defer t
  :config
  (c-add-style "pb style"
               '((c-basic-offset . 2)
                 (indent-tabs-mode . nil))))

;; JSON

(use-package json-mode
  :mode "\\.json\\'")

(use-package yaml-mode :defer t)

;; GraphQL

(use-package graphql-mode :defer t)
(add-to-list 'auto-mode-alist '("\\.graphqls\\'" . graphql-mode))

;; Nix / Environments

;; envrc only. Running direnv-mode alongside it meant two direnv integrations
;; shelling out over the same environment on every buffer switch.
(use-package envrc
  :config
  (envrc-global-mode))

(use-package nix-mode
  :mode "\\.nix\\'")

;; Terraform

(use-package terraform-mode :defer t)

;; Lsp

;; Golang stuff

;; No company-go: it drives gocode, which is not installed, and setting
;; company-backends locally cut out company-capf, which is how lsp-mode
;; serves completions.
(use-package go-mode
  :mode "\\.go\\'"
  :init
  (add-hook 'go-mode-hook
            (lambda ()
              (setq indent-tabs-mode 1)
              (setq tab-width 2))))

(use-package lsp-mode
  :pin melpa-stable
  :ensure t
  :commands (lsp lsp-deferred)
  :hook ((dhall-mode . lsp) (go-mode . lsp-deferred))
  :init
  ;; gopls sends large JSON payloads; the 64KB default means many more read
  ;; cycles per response.
  (setq read-process-output-max (* 1024 1024)
        lsp-idle-delay 0.5
        lsp-log-io nil))

(with-eval-after-load 'lsp-mode
  (add-to-list 'lsp-file-watch-ignored-directories "[/\\\\]\\.dist\\'"))

;; Set up before-save hooks to format buffer and add/delete imports.
;; Make sure you don't have other gofmt/goimports hooks enabled.
(defun lsp-go-install-save-hooks ()
  (add-hook 'before-save-hook #'lsp-format-buffer t t)
  (add-hook 'before-save-hook #'lsp-organize-imports t t))

(add-hook 'go-mode-hook #'lsp-go-install-save-hooks)

;; Optional - provides fancier overlays.
(use-package lsp-ui
  :ensure t
  :commands lsp-ui-mode)

;; Yasnippet
(use-package yasnippet
  :ensure t
  :commands yas-minor-mode
  :hook (go-mode . yas-minor-mode))

;; Typescript / TSX - Frontend Stuff
;; (dash-functional was merged into dash and is now an empty stub)

(use-package typescript-mode :defer t)

;; ATS2

(use-package ats-mode
  :ensure nil       ;; local copy; lisps/ is already on load-path
  ;; :commands rather than :defer, because this file carries no autoload
  ;; cookies, so nothing would define ats-mode when a .dats file is opened.
  :commands (ats-mode)
  :init
  (add-to-list 'auto-mode-alist '("\\.hats$" . ats-mode))
  (add-to-list 'auto-mode-alist '("\\.cats$" . ats-mode))
  (add-to-list 'auto-mode-alist '("\\.dats$" . ats-mode))
  (add-to-list 'auto-mode-alist '("\\.sats$" . ats-mode))
  (add-to-list 'auto-mode-alist '("\\.pats$" . ats-mode)))

;; JVM Stuff

(use-package kotlin-mode :defer t)

(use-package scala-mode
  :mode "\\.s\\(cala\\|bt\\)$")

(use-package sbt-mode
  :commands sbt-start sbt-command
  :config
  (substitute-key-definition
   'minibuffer-complete-word
   'self-insert-command
   minibuffer-local-completion-map)
   (setq sbt:program-options '("-Dsbt.supershell=false")))


(use-package gradle-mode :defer t)

;; Build Tools

(use-package dockerfile-mode :defer t)

(use-package bazel :defer t)

(use-package rust-mode :defer t)


;; Sundry other stuff

(use-package string-inflection :defer t)

;; Postgres-Style SQL Formatting
;; n.b. Requires pgformmater (see: nixpkgs.pgformatter)
(use-package sqlformat
  :mode ("\\.sql$" . sql-mode)
  :config
  (setq sqlformat-command `pgformatter))

;; Garbage collection.
;; A fixed 16MB threshold on a daemon that stays up for weeks produced tens of
;; thousands of collections mid-edit. gcmh holds the threshold high while you
;; work and collects once Emacs goes idle, so the pauses land between
;; keystrokes rather than during them. It also covers the minibuffer case the
;; old defer/restore hooks handled.
(use-package gcmh
  :ensure t
  :diminish
  :init
  (setq gcmh-idle-delay 'auto
        gcmh-auto-idle-delay-factor 10
        gcmh-high-cons-threshold (* 128 1024 1024))
  :config
  (gcmh-mode 1))

(provide 'init)

;;; init.el ends here
(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)
(put 'set-goal-column 'disabled nil)
