;; early-init.el -- Runs before the package system and the first frame -*- lexical-binding: t; -*-

;; Keep the garbage collector out of the way while init.el runs.
;; gcmh takes over once startup is done (see init.el).
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; Emacs 27+ activates every installed package before init.el is read.
;; init.el calls package-initialize itself, so without this the work is done twice.
(setq package-enable-at-startup nil)

;; Drop the UI elements before the first frame is drawn rather than
;; building them and tearing them down again.
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;;; early-init.el ends here
