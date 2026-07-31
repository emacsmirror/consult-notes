;;; install-deps.el --- Install test dependencies -*- lexical-binding: t -*-

;;; Commentary:
;; Installs the packages needed to compile and test consult-notes into
;; the .deps directory at the repository root. Run via `make deps'.

;;; Code:
(require 'package)
(setq package-user-dir (expand-file-name ".deps" default-directory))
(setq package-archives '(("gnu" . "https://elpa.gnu.org/packages/")))
(package-initialize)
(package-refresh-contents)
(dolist (pkg '(consult))
  (unless (package-installed-p pkg)
    (package-install pkg)))
(message "Dependencies installed in %s" package-user-dir)
;;; install-deps.el ends here
