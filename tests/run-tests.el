;;; run-tests.el --- Run the ERT suite in batch -*- lexical-binding: t -*-

;;; Commentary:
;; Loads the test file and runs all tests. Run via `make test'.

;;; Code:
(load (expand-file-name "tests/consult-notes-tests.el" default-directory) nil t)
(ert-run-tests-batch-and-exit)
;;; run-tests.el ends here
