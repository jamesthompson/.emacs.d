;;; init.el --- Personal Emacs configuration -*- lexical-binding: t; -*-

;;; Commentary:

;; Loaded after early-init.el, which sets the startup GC threshold and stops
;; package.el activating everything before this file runs.  gcmh takes over
;; garbage collection at the end of this file.

;;; Code:

;; Deep recursion in elisp (notably aggressive-indent and lsp) overruns the
;; 1600 default.
(setq max-lisp-eval-depth 2000)

;; Absolute, so that customize writes here rather than to whatever directory
;; Emacs happened to start in.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file 'noerror)

;; lisps/ holds packages that are not on any archive.  Loose .el files are
;; found directly; any subdirectory is added to the load path as well.  The
;; \w+ match skips "." and "..", which contain no word characters.
(defconst lisps-dir
  (expand-file-name "lisps" user-emacs-directory))

(add-to-list 'load-path lisps-dir)

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
  "Append SUFFIX to the list in TARGET, in place."
  `(setq ,target (append ,target ,suffix)))


;; use-package is the means to configure everything else

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))

;; Deferral is per package rather than global (the global switch is
;; `use-package-always-defer').  The UI packages have to load at startup to
;; take effect, so language and tool modes carry :defer t individually.
;; use-package-verbose logs per-package load times to *Messages*.
(setq use-package-always-ensure t
      use-package-verbose t)

;; Theme(s) & font(s) stuff

(set-face-attribute 'default nil :height 140)

(use-package doom-themes
  :config
  (load-theme 'doom-tomorrow-night :no-confirm)
  (doom-themes-visual-bell-config)
  (doom-themes-org-config)
  ;; Each face needs its own (FACE SPEC) argument.
  (custom-theme-set-faces
   'doom-tomorrow-night
   '(font-lock-doc-face ((t (:foreground "#D8D2C1"))))    ;; Lighten docstrings
   '(magit-diff-added ((t (:foreground "#D1FA71"))))      ;; Green for diff additions
   '(magit-diff-removed ((t (:foreground "#FAB1AB")))))) ;; Red for diff removals

;; Mac-specific defaults

;; The modifier settings only bite on a GUI (ns) build; this one is
;; terminal-only, so hyper in particular is unreachable there.
(defconst is-mac (eq system-type 'darwin))

(setq mac-option-modifier 'super
      mac-command-modifier 'meta  ;; Command acts as meta
      ns-function-modifier 'hyper ;; fn acts as hyper
      delete-by-moving-to-trash t
      trash-directory "~/.Trash/emacs"
      ns-pop-up-frames nil)       ;; Open files in this frame, not a new one

;; Under launchd the daemon inherits PATH=/usr/bin:/bin:/usr/sbin:/sbin, so the
;; shell environment has to be imported or gopls, cargo and kubectl are not
;; found.  The import needs an interactive zsh, because the PATH exports live
;; in .zshrc, and that costs about a second.  The result is therefore cached
;; and only recomputed when a shell init file changes.
;; Run M-x env-cache-refresh after adding a tool to PATH.
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
      global-auto-revert-non-file-buffers t                    ;; Auto refresh dired too
      auto-revert-verbose nil                                  ;; ...without announcing each revert
      vc-make-backup-files nil                                 ;; Version control already holds these
      select-enable-clipboard t                                ;; Share the kill ring with the system clipboard
      visible-bell t
      color-theme-is-global t
      truncate-partial-width-windows nil                       ;; Let split windows wrap like full-width ones
      shift-select-mode nil                                    ;; Do not use shift to mark things
      echo-keystrokes 0.1                                      ;; Echo keystrokes fast
      column-number-mode t
      fill-column 80
      history-length 1000
      enable-recursive-minibuffers t                           ;; Allow recursive minibuffers
      ;; Frees S-<arrow> for window movement; org moves those bindings to
      ;; M-p, M-n, M-- and M-+.  Must be set before org loads.
      org-replace-disputed-keys t
      eval-expression-print-level nil                          ;; Print eval results in full, no depth elision
      whitespace-style '(trailing lines space-before-tab
                                  indentation space-after-tab)
      whitespace-line-column 80
      dired-dwim-target t                                      ;; Default copy/move target is the other dired window
      inhibit-compacting-font-caches t)                        ;; Keeps icon font rendering fast (GUI only)

(defun current-buffer-matches-file-p ()
  "Return non-nil if the buffer text is identical to its file on disk.
Widens first, so a narrowed buffer is still compared in full."
  (let ((file buffer-file-name))
    (and file
         (file-readable-p file)
         (string= (save-restriction
                    (widen)
                    (buffer-substring-no-properties (point-min) (point-max)))
                  (with-temp-buffer
                    (insert-file-contents file)
                    (buffer-substring-no-properties (point-min) (point-max)))))))

(defun maybe-unset-buffer-modified (&optional _)
  "Clear the modified flag on buffers whose text still matches their file.
Stops Emacs prompting to save buffers that were only touched, not changed.
Reads each modified buffer's file, so keep it off any per-keystroke hook."
  (interactive)
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (and buffer-file-name (buffer-modified-p) (current-buffer-matches-file-p))
        (set-buffer-modified-p nil)))))

;; Don't prompt to save buffers that are unchanged on disk.
(advice-add 'save-buffers-kill-emacs :before #'maybe-unset-buffer-modified)

(if (fboundp 'menu-bar-mode)
    (menu-bar-mode -1))
(if (fboundp 'tool-bar-mode)
    (tool-bar-mode -1))
(if (fboundp 'scroll-bar-mode)
    (scroll-bar-mode -1))

(random t) ;; Seed the random-number generator

;; Answer y or n rather than typing yes or no in full.
(setq use-short-answers t)

;; UTF-8 everywhere
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-selection-coding-system 'utf-8)
(prefer-coding-system 'utf-8)

(global-hl-line-mode 1)                                  ;; Highlight the current line
(global-auto-revert-mode 1)                              ;; Reload buffers when the file changes on disk
(delete-selection-mode 1)                                ;; Typing replaces the active region
(auto-compression-mode t)                                ;; Open .gz and friends transparently
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(savehist-mode 1)                                        ;; Persist minibuffer history across restarts
(set-default 'indent-tabs-mode nil)                      ;; Indent with spaces
(set-default 'indicate-empty-lines t)                    ;; Mark lines past the end of the buffer
(global-subword-mode 1)                                  ;; Treat camelCase humps as words
(show-paren-mode 1)                                      ;; Highlight the paren matching the one at point

;; Code buffers only.  Two trailing spaces end a Markdown line with a hard
;; break, so stripping them everywhere rewrites prose on save.  Go is excluded
;; because gopls already strips trailing whitespace through `lsp-format-buffer'
;; below, and running both walks the buffer twice per save.
(defun enable-trailing-whitespace-trim ()
  (unless (derived-mode-p 'go-mode)
    (add-hook 'before-save-hook #'delete-trailing-whitespace nil t)))

(add-hook 'prog-mode-hook #'enable-trailing-whitespace-trim)

;; Buffer-local so a region in one buffer does not deactivate on switching,
;; and permanent-local so it survives a major mode change.
(transient-mark-mode 1)
(make-variable-buffer-local 'transient-mark-mode)
(put 'transient-mark-mode 'permanent-local t)

(setq-default transient-mark-mode t
              truncate-lines t)                          ;; Truncate rather than wrap long lines

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

;; Revert dired automatically after any command that changes the directory.
;; Named rather than a lambda, so the advice can be removed again.
(defun dired-revert-after-change (&rest _)
  "Refresh the listing after a command that changed the directory."
  (revert-buffer))

(dolist (cmd '(dired-do-rename
               dired-do-copy
               dired-create-directory
               wdired-abort-changes))
  (advice-add cmd :after #'dired-revert-after-change))

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

;; Makefiles need real tabs.  Call the mode with an argument: bare
;; `indent-tabs-mode' as a hook function toggles, so it would turn tabs back
;; off wherever they are already on.
(add-hook 'makefile-mode-hook (lambda () (indent-tabs-mode 1)))

;; Declared, not loaded: the `let' below has to bind this dynamically, and
;; comint.el is only required once `clear-shell' actually runs.
(defvar comint-buffer-maximum-size)

(defun clear-shell ()
  "Delete all output in the current comint buffer except the last prompt.
Falls back to erasing the buffer once the process has exited, since
`comint-truncate-buffer' needs a live process to locate the prompt."
  (interactive)
  (require 'comint)
  (if (get-buffer-process (current-buffer))
      (let ((comint-buffer-maximum-size 0))
        (comint-truncate-buffer))
    (let ((inhibit-read-only t))
      (erase-buffer))))

(add-hook 'shell-mode-hook
          (lambda ()
            (local-set-key (kbd "M-k") 'clear-shell)))

;; Paredit for emacs-lisp-mode
(use-package paredit
  :ensure t
  :hook (emacs-lisp-mode . paredit-mode))

;; Global key bindings

(defun untabify-buffer ()
  (interactive)
  (untabify (point-min) (point-max)))

(defun indent-buffer ()
  (interactive)
  (indent-region (point-min) (point-max)))

(defun cleanup-buffer ()
  "Untabify, strip trailing whitespace and reindent the whole buffer.
Reindentation is why this is not on `before-save-hook'."
  (interactive)
  (untabify-buffer)
  (delete-trailing-whitespace)
  (indent-buffer))

;; Flip a two-window split between side by side and stacked.
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

(defun region-as-string ()
  "Return the text of the active region."
  (buffer-substring-no-properties (region-beginning) (region-end)))

;; Like isearch, but seeds the search ring with the active region first.
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
(defun create-scratch-buffer ()
  "Switch to a new scratch buffer in `emacs-lisp-mode'.
Names it *scratch*, or *scratch1*, *scratch2* and so on if taken."
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

(defun kill-region-or-backward-word ()
  "Kill the active region, or the word before point when there is none."
  (interactive)
  (if (region-active-p)
      (kill-region (region-beginning) (region-end))
    (backward-kill-word 1)))

;; Force a save even when the buffer is unmodified, to bump the file mtime.
(defun touch-buffer-file ()
  (interactive)
  (insert " ")
  (backward-delete-char 1)
  (save-buffer))

(defun rename-current-buffer-file ()
  "Rename the current buffer and the file it is visiting."
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

;; Make C-h act as backspace, shell style.  help-command moves to C-H below.
(define-key key-translation-map [?\C-h] [?\C-?])

;; Keyboard macro: C-x b RET, which accepts the default and so toggles to the
;; previous buffer.  Not bound to a key.
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
(global-set-key (kbd "H-*") 'beginning-of-buffer)            ;; Hyper, so GUI builds only
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

;; Loaded eagerly on purpose: `ffip-project-files' below redefines a function
;; from this package, so the package has to be in place first or the override
;; is undone when it loads later.
(use-package find-file-in-project)

(setq ffip-limit 4096)

(defun ffip-project-files ()
  "Return an alist mapping project-relative file names to absolute paths.
Overrides the ffip function of the same name so candidates show the path
from the project root rather than the bare file name."
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

;; Build a command that searches only the given file name PATTERNS.
;; This file is lexically bound, so a plain `let' closes over patterns;
;; `lexical-let' is from cl and is not available here.
(defun ffip-create-pattern-file-finder (&rest patterns)
  (lambda ()
    (interactive)
    (let ((ffip-patterns patterns))
      (find-file-in-project))))

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

;; Making C-x g a prefix also keeps magit from claiming C-x g globally, which
;; its autoloads do on `after-init-hook' when the key is still free.
(global-set-key (kbd "C-x g l") 'goto-line)

;; s.el, for the string helpers used just below
(use-package s)

(defvar user-home-directory (concat (expand-file-name "~") "/"))

(defun shorter-file-name (file-name)
  (s-chop-prefix user-home-directory file-name))

(defun recentf--file-cons (file-name)
  "Pair the display name of FILE-NAME with its full path."
  (cons (shorter-file-name file-name) file-name))

;; recentf
(use-package recentf
  :init (recentf-mode t)
  :config
  (add-to-list 'recentf-exclude "\\.emacs.d")
  (add-to-list 'recentf-exclude ".+tmp......\\.org"))

(defun recentf-ido-find-file ()
  "Open a recent file, shown relative to home.
Routed through ido by `ido-ubiquitous-mode', set up further down."
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


;; Not on C-i: in a terminal C-i is TAB, and binding it there would remove TAB
;; everywhere, including indentation, completion-at-point and org cycling.
;; C-x TAB <left> <right> still does interactive rigid indentation.
(global-set-key (kbd "C-c i") 'indent-region)

(defun hippie-expand-no-case-fold ()
  "Expand the word before point with `hippie-expand', matching case exactly."
  (interactive)
  (let ((case-fold-search nil))
    (hippie-expand nil)))

(global-set-key (kbd "C-c E") 'hippie-expand-no-case-fold)

;; Package loading / setup

;; Modeline uncluttering
(use-package diminish
  :ensure t)

;; Hide these from the modeline.  Some name modes from packages that are not
;; installed; diminish tolerates that.
(diminish 'eldoc-mode)
(diminish 'paredit-mode)
(diminish 'elisp-slime-nav)
(diminish 'smartparens-mode)
(diminish 'guide-key-mode)
(diminish 'whitespace-cleanup-mode)
(diminish 'subword-mode)

;; Lisp only.  It reindents the enclosing block on every change, which is
;; expensive in large Go, TS and JSON buffers.
(use-package aggressive-indent
  :hook ((emacs-lisp-mode lisp-mode scheme-mode) . aggressive-indent-mode)
  :diminish)

(use-package doom-modeline
  :ensure t
  :hook (after-init . doom-modeline-mode)
  :config
  (doom-modeline-def-modeline 'plain-modeline
    '(bar major-mode matches buffer-info vcs buffer-position parrot selection-info)
    '(misc-info minor-modes input-method buffer-encoding process))
  (setq doom-modeline-height 32
        doom-modeline-bar-width 6
        doom-modeline-minor-modes nil     ;; Listing every minor mode costs a redisplay pass
        doom-modeline-buffer-file-name-style 'truncate-upto-project
        doom-modeline-vcs-max-length 32
        doom-modeline-indent-info t)
  ;; nil on a terminal build, so icons stay off there.
  (when window-system
    (setq doom-modeline-icon t
          doom-modeline-major-mode-icon t
          doom-modeline-major-mode-color-icon t))
  (doom-modeline-set-modeline 'plain-modeline 'default))

;; ido stuff
(use-package flx-ido
  :init (flx-ido-mode 1))

;; C-n, C-p and the arrow keys step through matches rather than history, which
;; is what a vertical list wants.  `ido-vertical-define-keys' defaults to nil,
;; so without setting it the keys keep their flat-list meanings.
(use-package ido-vertical-mode
  :init
  (setq ido-vertical-define-keys 'C-n-C-p-up-and-down)
  (ido-vertical-mode))

(use-package ido-at-point
  :init (ido-at-point-mode))

(use-package ido-completing-read+
  :init (ido-ubiquitous-mode 1))

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

;; Deadgrep (ripgrep within Emacs; needs rg on PATH)
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
  :config
  (defun adjust-flycheck-automatic-syntax-eagerness ()
    "Recheck quickly while errors are present, slowly once the buffer is clean."
    (setq flycheck-idle-change-delay
          (if flycheck-current-errors 0.5 30.0)))

  ;; Per buffer, because the delay above is adjusted per buffer.
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
  ;; :demand overrides the deferral that :bind implies, so global-company-mode
  ;; below runs at startup rather than on the first C-c e.
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
  ;; Keep these off zero and one: that combination queries the backend on
  ;; every keystroke from the first character, which floods LSP.
  (setq company-idle-delay 0.15
        company-minimum-prefix-length 2)
  ;; Pick a candidate by its number, 0 to 9
  (let ((map company-active-map))
    (mapc (lambda (x) (define-key map (format "%d" x)
                        `(lambda () (interactive) (company-complete-number ,x))))
          (number-sequence 0 9))))

;; Haskell

(use-package haskell-mode
  :mode ("\\.hs\\'" . haskell-mode)
  :config
  (add-hook 'haskell-mode-hook 'turn-on-haskell-indentation))

;; Protobuf

(use-package protobuf-mode
  :ensure t
  :defer t
  :config
  ;; Registered but not selected; set c-default-style to use it.
  (c-add-style "pb style"
               '((c-basic-offset . 2)
                 (indent-tabs-mode . nil))))

;; JSON

(use-package json-mode
  :mode "\\.json\\'")

(use-package yaml-mode :defer t)

;; GraphQL

;; The package autoloads .graphql; .graphqls needs adding.
(use-package graphql-mode
  :defer t
  :mode ("\\.graphqls\\'" . graphql-mode))

;; Nix / Environments

;; envrc, not direnv.el: it keeps the environment buffer-local, so buffers
;; from different projects do not overwrite each other's environment.
(use-package envrc
  :config
  (envrc-global-mode))

(use-package nix-mode
  :mode "\\.nix\\'")

;; Terraform

(use-package terraform-mode :defer t)

;; Lsp

;; Golang stuff

;; Completion comes from lsp-mode through company-capf, so nothing here should
;; set company-backends: replacing that list locally would cut gopls out.
(use-package go-mode
  :mode "\\.go\\'"
  :init
  (add-hook 'go-mode-hook
            (lambda ()
              (setq indent-tabs-mode t)   ;; gofmt wants tabs
              (setq tab-width 2))))

(use-package lsp-mode
  :pin melpa-stable
  :ensure t
  :commands (lsp lsp-deferred)
  :hook (go-mode . lsp-deferred)
  :init
  ;; gopls sends large JSON payloads, and the 64KB default splits each one
  ;; across many more reads.  lsp-log-io stays off; it is costly.
  (setq read-process-output-max (* 1024 1024)
        lsp-idle-delay 0.5
        lsp-log-io nil))

(with-eval-after-load 'lsp-mode
  (add-to-list 'lsp-file-watch-ignored-directories "[/\\\\]\\.dist\\'"))

;; Format and fix imports on save, via gopls.  Do not add gofmt or goimports
;; hooks as well, or the buffer gets formatted twice.
(defun lsp-go-install-save-hooks ()
  (add-hook 'before-save-hook #'lsp-format-buffer t t)
  (add-hook 'before-save-hook #'lsp-organize-imports t t))

(add-hook 'go-mode-hook #'lsp-go-install-save-hooks)

;; Sideline and peek overlays for lsp-mode, enabled per buffer.
(use-package lsp-ui
  :ensure t
  :commands lsp-ui-mode)

;; Yasnippet
(use-package yasnippet
  :ensure t
  :commands yas-minor-mode
  :hook (go-mode . yas-minor-mode))

;; Typescript / TSX - Frontend Stuff

(use-package typescript-mode :defer t)

;; ATS2

;; Local copy in lisps/, which is already on the load path.  It carries no
;; autoload cookies, so :commands is what defines ats-mode for the file
;; associations below.
(use-package ats-mode
  :ensure nil
  :commands (ats-mode)
  :mode (("\\.hats\\'" . ats-mode)
         ("\\.cats\\'" . ats-mode)
         ("\\.dats\\'" . ats-mode)
         ("\\.sats\\'" . ats-mode)
         ("\\.pats\\'" . ats-mode)))

;; Build Tools

(use-package dockerfile-mode :defer t)

(use-package bazel :defer t)

(use-package rust-mode :defer t)


;; Sundry other stuff

(use-package string-inflection :defer t)

;; Postgres-style SQL formatting via M-x sqlformat.
;; Needs the pgformatter binary on PATH (nixpkgs.pgformatter).
(use-package sqlformat
  :mode ("\\.sql\\'" . sql-mode)
  :config
  (setq sqlformat-command 'pgformatter))

;; Garbage collection.
;; This config runs as a long-lived daemon, where a fixed threshold means
;; thousands of collections in the middle of editing.  gcmh keeps the
;; threshold high while you work and collects once Emacs goes idle, so pauses
;; land between keystrokes rather than during them.
(use-package gcmh
  :ensure t
  :diminish
  :init
  (setq gcmh-idle-delay 'auto
        gcmh-auto-idle-delay-factor 10
        gcmh-high-cons-threshold (* 128 1024 1024))
  :config
  (gcmh-mode 1))

;; Stop Emacs asking for confirmation on these.
(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)
(put 'set-goal-column 'disabled nil)

(provide 'init)

;;; init.el ends here
