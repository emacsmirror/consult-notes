;;; compile.el --- Byte-compile with warnings as errors -*- lexical-binding: t -*-

;;; Commentary:
;; Byte-compiles every source file with `byte-compile-error-on-warn' so
;; that any warning fails the build. Output goes to a scratch file, not
;; the repository. Run via `make compile'.

;;; Code:
(setq byte-compile-error-on-warn t)
(setq byte-compile-dest-file-function
      (lambda (_f)
        (expand-file-name "consult-notes-compile-check.elc"
                          temporary-file-directory)))
(let ((failed nil))
  (dolist (f '("consult-notes.el"
               "consult-notes-denote.el"
               "consult-notes-org-headings.el"
               "consult-notes-org-roam.el"))
    (message "Compiling %s" f)
    (unless (byte-compile-file (expand-file-name f default-directory))
      (setq failed t)))
  (if failed
      (kill-emacs 1)
    (message "Byte-compilation clean.")))
;;; compile.el ends here
