;;; init-deps.el --- Initialize test dependencies -*- lexical-binding: t -*-

;;; Commentary:
;; Adds the .deps package directory and the repository root to the load
;; path. Loaded before compiling or running tests.

;;; Code:
(require 'package)
(setq package-user-dir (expand-file-name ".deps" default-directory))
(package-initialize)
(add-to-list 'load-path default-directory)
;;; init-deps.el ends here
