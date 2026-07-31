;;; consult-notes-tests.el --- ERT tests for consult-notes -*- lexical-binding: t -*-

;;; Commentary:
;; Pure-logic tests for consult-notes. External backends (denote,
;; org-roam) are stubbed with `cl-letf' so the tests run without them
;; installed and are deterministic when they are. Run with `make check'
;; from the repository root.

;;; Code:
(require 'ert)
(require 'cl-lib)
(require 'consult-notes)
(require 'consult-notes-org-headings)
(require 'consult-notes-denote)
(ignore-errors (require 'consult-notes-org-roam))

;; The sources placate the byte-compiler with value-less `defvar' forms,
;; which mark these special only within their own file. Declare them
;; here so `let'-binding them in tests is dynamic.
(defvar denote-directory)
(defvar org-roam-directory)
(defvar org-roam-dailies-directory)

;;;; File matching

(ert-deftest consult-notes-test-file-match ()
  "`consult-notes-file-match' includes and excludes the right names."
  (dolist (name '("foo.md" "foo.c" "a.b" "foo.org" "archive.tar.gz"))
    (should (string-match-p consult-notes-file-match name)))
  (dolist (name '(".hidden.org" "foo.org~" "foo~" "README" "foo."))
    (should-not (string-match-p consult-notes-file-match name))))

;;;; Time formatting

(ert-deftest consult-notes-test-time-relative ()
  "Relative ages format with the right unit and pluralization."
  (should (equal "30 secs ago"
                 (consult-notes--time-relative
                  (time-subtract (current-time) 30))))
  (should (equal "2 hours ago"
                 (consult-notes--time-relative
                  (time-subtract (current-time) 7200)))))

;;;; File-dir sources

(ert-deftest consult-notes-test-file-dir-sources-regenerate ()
  "Regenerating file-dir sources neither duplicates nor leaks stale entries."
  (let* ((dir1 (make-temp-file "cn-dir1" t))
         (dir2 (make-temp-file "cn-dir2" t))
         (consult-notes-all-sources nil)
         (consult-notes--file-dir-sources nil))
    (unwind-protect
        (progn
          (let ((consult-notes-file-dir-sources `(("One" ?o ,dir1))))
            (consult-notes--make-file-dir-sources)
            (consult-notes--make-file-dir-sources)
            (should (= 1 (length consult-notes-all-sources))))
          (let ((consult-notes-file-dir-sources `(("Two" ?t ,dir2))))
            (consult-notes--make-file-dir-sources)
            (should (= 1 (length consult-notes-all-sources)))
            (should (equal "Two"
                           (substring-no-properties
                            (plist-get (car consult-notes-all-sources) :name))))))
      (delete-directory dir1 t)
      (delete-directory dir2 t))))

;;;; Mode toggles

(ert-deftest consult-notes-test-denote-mode-toggle ()
  "Disabling the denote mode removes its source, even at the head of the list."
  (let ((consult-notes-all-sources nil))
    (consult-notes-denote-mode 1)
    (should (memq 'consult-notes-denote--source consult-notes-all-sources))
    (consult-notes-denote-mode -1)
    (should-not (memq 'consult-notes-denote--source consult-notes-all-sources))))

;;;; Org-headings file resolution

(defun consult-notes-tests--with-note-files (fn)
  "Call FN with a temp directory containing a.org, b.org, and c.txt."
  (let ((dir (make-temp-file "cn-org" t)))
    (unwind-protect
        (progn
          (with-temp-file (expand-file-name "a.org" dir) (insert "* A\n"))
          (with-temp-file (expand-file-name "b.org" dir) (insert "* B\n"))
          (with-temp-file (expand-file-name "c.txt" dir) (insert "x\n"))
          (funcall fn dir))
      (delete-directory dir t))))

(defun consult-notes-tests--basenames ()
  "Resolve org-headings files and return sorted basenames."
  (sort (mapcar #'file-name-nondirectory (consult-notes-org-headings-files))
        #'string<))

(ert-deftest consult-notes-test-org-headings-files-nil ()
  "nil delegates to the current `org-agenda-files'."
  (consult-notes-tests--with-note-files
   (lambda (dir)
     (let ((consult-notes-org-headings-files nil)
           (org-agenda-files (list (expand-file-name "a.org" dir))))
       (should (equal '("a.org") (consult-notes-tests--basenames)))))))

(ert-deftest consult-notes-test-org-headings-files-directory ()
  "A directory in the list expands to the org files inside it."
  (consult-notes-tests--with-note-files
   (lambda (dir)
     (let ((consult-notes-org-headings-files (list dir)))
       (should (equal '("a.org" "b.org") (consult-notes-tests--basenames)))))))

(ert-deftest consult-notes-test-org-headings-files-function ()
  "A function value is called for the file list."
  (consult-notes-tests--with-note-files
   (lambda (dir)
     (let ((consult-notes-org-headings-files
            (lambda () (list (expand-file-name "b.org" dir)))))
       (should (equal '("b.org") (consult-notes-tests--basenames)))))))

(ert-deftest consult-notes-test-org-headings-files-skip-unavailable ()
  "Unreadable files are dropped when org says to skip them."
  (consult-notes-tests--with-note-files
   (lambda (dir)
     (let ((consult-notes-org-headings-files
            (list (expand-file-name "a.org" dir)
                  (expand-file-name "missing.org" dir)))
           (org-agenda-skip-unavailable-files t))
       (should (equal '("a.org") (consult-notes-tests--basenames)))))))

(ert-deftest consult-notes-test-org-headings-files-invalid ()
  "An invalid value signals an error."
  (let ((consult-notes-org-headings-files 42))
    (should-error (consult-notes-org-headings-files))))

;;;; Denote candidates

(defun consult-notes-tests--with-denote-stubs (thunk)
  "Run THUNK with a stubbed denote API."
  (cl-letf (((symbol-function 'denote-retrieve-filename-identifier)
             (lambda (f)
               (let ((base (file-name-nondirectory f)))
                 (when (string-match "\\`\\([0-9T]+\\)" base)
                   (match-string 1 base)))))
            ((symbol-function 'denote-retrieve-title-value)
             (lambda (_f _ft) nil))
            ((symbol-function 'denote-filetype-heuristics)
             (lambda (_f) nil))
            ((symbol-function 'denote-retrieve-filename-title)
             (lambda (f)
               (let ((base (file-name-nondirectory f)))
                 (when (string-match "--\\([^.]+\\)" base)
                   (match-string 1 base)))))
            ((symbol-function 'denote-extract-keywords-from-path)
             (lambda (_f) '("kw"))))
    (funcall thunk)))

(defconst consult-notes-tests--denote-files
  '("/tmp/denotes/20240101T000000--same.org"
    "/tmp/denotes/20240202T000000--same.org"
    "/tmp/denotes/20240303T000000--other.org"))

(ert-deftest consult-notes-test-denote-duplicate-disambiguation ()
  "Colliding candidates get an ID suffix; unique ones do not."
  (consult-notes-tests--with-denote-stubs
   (lambda ()
     (let* ((denote-directory "/tmp/denotes/")
            (consult-notes-denote-display-id nil)
            (consult-notes-denote-files-function
             (lambda () consult-notes-tests--denote-files))
            (items (funcall (plist-get consult-notes-denote--source :items))))
       (should (= 3 (length items)))
       (should (= 3 (length (delete-dups
                             (mapcar #'substring-no-properties items)))))
       (should (string-match-p "<20240101T000000>" (nth 0 items)))
       (should (string-match-p "<20240202T000000>" (nth 1 items)))
       (should-not (string-match-p "<" (nth 2 items)))))))

(ert-deftest consult-notes-test-denote-no-suffix-with-id ()
  "With IDs displayed, titles are already unique and get no suffix."
  (consult-notes-tests--with-denote-stubs
   (lambda ()
     (let* ((denote-directory "/tmp/denotes/")
            (consult-notes-denote-display-id t)
            (consult-notes-denote-files-function
             (lambda () consult-notes-tests--denote-files))
            (items (funcall (plist-get consult-notes-denote--source :items))))
       (should (= 3 (length items)))
       (should-not (seq-some (lambda (c) (string-match-p " <[0-9T]+>" c))
                             items))))))

;;;; Org-roam candidates

(defun consult-notes-tests--with-org-roam-stubs (thunk)
  "Run THUNK with a stubbed org-roam node API over plists."
  (cl-letf (((symbol-function 'org-roam-node-file)
             (lambda (n) (plist-get n :file)))
            ((symbol-function 'org-roam-node-id)
             (lambda (n) (plist-get n :id)))
            ((symbol-function 'org-roam-node-title)
             (lambda (n) (plist-get n :title))))
    (funcall thunk)))

(ert-deftest consult-notes-test-org-roam-display-string ()
  "Blank formatted strings fall back to filename, then ID."
  (skip-unless (featurep 'consult-notes-org-roam))
  (consult-notes-tests--with-org-roam-stubs
   (lambda ()
     (let ((node '(:file "/notes/x.org" :id "12345678abc" :title "X")))
       (should (equal "title"
                      (consult-notes-org-roam--display-string "title" node)))
       (should (equal "x"
                      (consult-notes-org-roam--display-string "   " node)))
       (should (equal "x"
                      (consult-notes-org-roam--display-string nil node)))))))

(ert-deftest consult-notes-test-org-roam-make-candidates ()
  "Duplicate titles get ID suffixes and dailies are excluded."
  (skip-unless (featurep 'consult-notes-org-roam))
  (consult-notes-tests--with-org-roam-stubs
   (lambda ()
     (let* ((org-roam-directory "/roam/")
            (org-roam-dailies-directory "daily/")
            (consult-notes-org-roam-exclude-dailies t)
            (n1 '(:file "/roam/a.org" :id "aaaaaaaa1" :title "Same"))
            (n2 '(:file "/roam/b.org" :id "bbbbbbbb2" :title "Same"))
            (n3 '(:file "/roam/daily/d.org" :id "cccccccc3" :title "Daily"))
            (cands (consult-notes-org-roam--make-candidates
                    (list (cons "Same" n1) (cons "Same" n2) (cons "Daily" n3)))))
       (should (= 2 (length cands)))
       (should (string-match-p "<aaaaaaaa>" (nth 0 cands)))
       (should (string-match-p "<bbbbbbbb>" (nth 1 cands)))
       (should (equal n1 (get-text-property 0 'node (nth 0 cands))))))))

(provide 'consult-notes-tests)
;;; consult-notes-tests.el ends here
