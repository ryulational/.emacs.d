;; Elpaca
(defvar elpaca-installer-version 0.11)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

(elpaca elpaca-use-package
  ;; Enable Elpaca support for use-package's :ensure keyword.
  (elpaca-use-package-mode))

(unless (file-exists-p "~/.emacs.d/custom.el")
  (write-region "" nil "~/.emacs.d/custom.el"))
(setq custom-file "~/.emacs.d/custom.el")
(load custom-file)

(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))

(global-display-line-numbers-mode)
(global-visual-line-mode)

(tool-bar-mode -1)

(setq require-final-newline t)

(when (member "Liberation Mono" (font-family-list))
  (set-frame-font "Liberation Mono" t t))

(use-package editorconfig
  :ensure t
  :config
  (editorconfig-mode 1))

(use-package zenburn-theme
  :ensure t
  :init
  (load-theme 'zenburn t))

(use-package ivy
  :ensure t
  :config
  (ivy-mode 1)
  (setq ivy-use-selectable-prompt t))

(use-package counsel
  :ensure t
  :config
  (counsel-mode 1)
  :bind
  (("C-r" . counsel-rg)))

(use-package swiper
  :ensure t
  :bind
  (("\C-s" . swiper)))

;;
;; just
;;
(use-package just-mode
  :ensure t)

;;
;; YAML
;;
(use-package yaml-mode
  :ensure t
  :config
  (add-to-list 'auto-mode-alist '("\\.yaml\\'" . yaml-mode)))
