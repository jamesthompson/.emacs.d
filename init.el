;; Turn off mouse interface early in startup to avoid momentary display

;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(package-initialize)

(if (fboundp 'menu-bar-mode) (menu-bar-mode -1))
(if (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

;; Splash and scratch msgs
(setq inhibit-startup-message t)
(setq initial-scratch-message ";; Scratch")

;; Set path to dependencies
(setq site-lisp-dir
      (expand-file-name "site-lisp" user-emacs-directory))

(setq settings-dir
      (expand-file-name "settings" user-emacs-directory))

;; Set up load path
(add-to-list 'load-path settings-dir)
(add-to-list 'load-path site-lisp-dir)

;; Keep emacs Custom-settings in separate file
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file)

;; Set up appearance early
(require 'appearance)

;; Settings for currently logged in user
(setq user-settings-dir
      (concat user-emacs-directory "Users/" user-login-name))
(add-to-list 'load-path user-settings-dir)

;; Add external projects to load path
(dolist (project (directory-files site-lisp-dir t "\\w+"))
  (when (file-directory-p project)
    (add-to-list 'load-path project)))

;; Write backup files to own directory
(setq backup-directory-alist
      `(("." . ,(expand-file-name
                 (concat user-emacs-directory "backups")))))

;; Make backups of files, even when they're in version control
(setq vc-make-backup-files t)

;; Save point position between sessions
(require 'saveplace)
(setq-default save-place t)
(setq save-place-file (expand-file-name ".places" user-emacs-directory))

;; Are we on a mac?
(setq is-mac (equal system-type 'darwin))
(setq james/default-font "-apple-Meslo LG S for Powerline-normal-normal-normal-*-10-*-*-*-m-0-iso10646-1")
(setq james/presentation-font "-apple-Monaco-medium-normal-normal-*-21-*-*-*-m-0-iso10646-1")
(set-face-attribute 'default nil :font james/default-font)

;; Setup packages
(require 'setup-package)

;; Install extensions if they're missing
(defun init--install-packages ()
  (packages-install
   '(dash
     haskell-mode
     magit
     paredit
     move-text
     gist
     htmlize
     visual-regexp
     markdown-mode
     fill-column-indicator
     flycheck
     flycheck-pos-tip
     flx
     flx-ido
     dired-details
     css-eldoc
     yasnippet
     smartparens
     ido-vertical-mode
     ido-at-point
     idris-mode
     simple-httpd
     guide-key
     restclient
     highlight-escape-sequences
     whitespace-cleanup-mode
     elisp-slime-nav
     dockerfile-mode
     prodigy
     protobuf-mode
     rainbow-delimiters
     hcl-mode
     terraform-mode
     purescript-mode
     string-inflection
     intero
     psc-ide
     perspective
     smex
     ido-ubiquitous
     find-file-in-project
     multiple-cursors
     jump-char
     wgrep
     smart-forward
     multifiles
     neotree
     dash-at-point
     anaconda-mode
     kotlin-mode
     )))

(condition-case nil
    (init--install-packages)
  (error
   (package-refresh-contents)
   (init--install-packages)))

;; Lets start with a smattering of sanity
(require 'sane-defaults)

;; Setup environment variables from the user's shell.
(when is-mac
  (require-package 'exec-path-from-shell)
  (exec-path-from-shell-initialize))

;; guide-key
(require 'guide-key)
(setq guide-key/guide-key-sequence '("C-x r" "C-x 4" "C-x v" "C-x 8" "C-x +"))
(guide-key-mode 1)
(setq guide-key/recursive-key-sequence-flag t)
(setq guide-key/popup-window-position 'bottom)

;; Setup extensions
(eval-after-load 'ido '(require 'setup-ido))
(eval-after-load 'org '(require 'setup-org))
(eval-after-load 'dired '(require 'setup-dired))
(eval-after-load 'magit '(require 'setup-magit))
(eval-after-load 'grep '(require 'setup-rgrep))
(eval-after-load 'shell '(require 'setup-shell))
(require 'setup-hippie)
(require 'setup-yasnippet)
(require 'setup-perspective)
(require 'setup-ffip)
(require 'setup-html-mode)
(require 'setup-paredit)
(require 'setup-dash)
(require 'setup-powerline)

(require 'prodigy)
(global-set-key (kbd "C-x M-m") 'prodigy)

;; Font lock dash.el
(eval-after-load "dash" '(dash-enable-font-lock))

;; Default setup of smartparens
(require 'smartparens-config)
(setq sp-autoescape-string-quote nil)
(--each '(css-mode-hook
          restclient-mode-hook
          js-mode-hook
          java-mode
          markdown-mode)
  (add-hook it 'turn-on-smartparens-mode))

;; Language specific setup files
(eval-after-load 'haskell-mode '(require 'setup-haskell))
(eval-after-load 'kotlin-mode '(require 'setup-kotlin))
(eval-after-load 'js2-mode '(require 'setup-js2-mode))
(eval-after-load 'markdown-mode '(require 'setup-markdown-mode))
(eval-after-load 'java-mode '(require 'setup-java))
(require 'setup-python)
(require 'setup-purescript)

;; Load stuff on demand
(autoload 'skewer-start "setup-skewer" nil t)
(autoload 'skewer-demo "setup-skewer" nil t)
(autoload 'auto-complete-mode "auto-complete" nil t)
(eval-after-load 'flycheck '(require 'setup-flycheck))

;; Map files to modes
(require 'mode-mappings)

;; Highlight escape sequences
(require 'highlight-escape-sequences)
(hes-mode)
(put 'font-lock-regexp-grouping-backslash 'face-alias 'font-lock-builtin-face)

;; Visual regexp
(require 'visual-regexp)
(define-key global-map (kbd "M-&") 'vr/query-replace)
(define-key global-map (kbd "M-/") 'vr/replace)

;; Functions (load all files in defuns-dir)
(setq defuns-dir (expand-file-name "defuns" user-emacs-directory))
(dolist (file (directory-files defuns-dir t "\\w+"))
  (when (file-regular-p file)
    (load file)))

(require 'expand-region)
(require 'multiple-cursors)
(require 'delsel)
(require 'jump-char)
(require 'eproject)
(require 'wgrep)
(require 'smart-forward)
(require 'change-inner)
(require 'multifiles)
(require 'setup-neotree)
(require 'nix-mode)
(require 'protobuf-mode)

;; Don't use expand-region fast keys
(setq expand-region-fast-keys-enabled nil)

;; Show expand-region command used
(setq er--show-expansion-message t)

;; Fill column indicator
(require 'fill-column-indicator)
(setq fci-rule-color "#111122")

;; Browse kill ring
(require 'browse-kill-ring)
(setq browse-kill-ring-quit-action 'save-and-restore)

;; Smart M-x is smart
(require 'smex)
(smex-initialize)

;; Setup key bindings
(require 'key-bindings)

;; Misc
(require 'project-archetypes)
(require 'my-misc)

;; Always engage mac mode
(require 'mac)

;; Elisp go-to-definition with M-. and back again with M-,
(autoload 'elisp-slime-nav-mode "elisp-slime-nav")
(add-hook 'emacs-lisp-mode-hook (lambda () (elisp-slime-nav-mode t) (eldoc-mode 1)))

;; Emacs server
(require 'server)
(unless (server-running-p)
  (server-start))

;; Run at full power please
(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)
(put 'narrow-to-region 'disabled nil)

;; Conclude init by setting up specifics for the current user
(when (file-exists-p user-settings-dir)
  (mapc 'load (directory-files user-settings-dir nil "^[^#].*el$")))

