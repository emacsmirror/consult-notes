# Changelog

## 0.9

### Fixes

- **File matching**: `consult-notes-file-match` is now anchored, so dotfiles
  are excluded (previously the unanchored match let them through) and files
  with single-character extensions are included (previously excluded). Its
  docstring, corrupted by a stray quote, is repaired.
- **Embark/marginalia integration**: the org-roam sources declared their
  completion category as `(quote org-roam-node)` instead of the bare symbol,
  breaking category dispatch for embark actions and marginalia annotators.
- **Dailies exclusion**: `consult-notes-org-roam-exclude-dailies` expanded
  `org-roam-dailies-directory` against the current working directory; it now
  expands against `org-roam-directory` and actually excludes dailies.
- **Org-roam preview**: previews now scroll to the node's position in the
  window showing the preview (previously `set-window-start` ran on the
  minibuffer window before the buffer was opened), and all state actions are
  forwarded so cleanup on exit is reliable.
- **Mode toggles**: disabling `consult-notes-denote-mode`,
  `consult-notes-org-roam-mode`, or `consult-notes-org-headings-mode` now
  reliably removes their sources (the `delete` result was discarded, so a
  source at the head of the list was never removed).
- **Stale sources**: file-dir sources are regenerated on each `consult-notes`
  call, so directories removed from `consult-notes-file-dir-sources` no
  longer linger until restart.
- **Org-headings annotations**: file size and modification time are read from
  the heading's marker buffer instead of regexp-matching buffer names against
  the config variable, fixing spurious "0 secs ago" annotations.
- **Denote alignment**: the keyword column position no longer depends on
  candidate order, and the keyword display honors
  `consult-notes-denote-display-keywords-width`.
- **Annotation performance**: org-roam annotations only query the database
  for backlink counts and stat the file for size when
  `consult-notes-org-roam-blinks` / `consult-notes-org-roam-show-file-size`
  are enabled.

### Denote

- **Duplicate candidates**: notes whose title, keywords, and directory all
  coincide (possible when `consult-notes-denote-display-id` is nil) are now
  disambiguated with an ID suffix instead of collapsing to a single entry
  that always opened the first note.

### Org-Headings

- **Dynamic file list**: `consult-notes-org-headings-files` now defaults to
  nil, meaning the current value of `org-agenda-files` resolved at call time
  rather than a snapshot taken when the extension loads. The value may also
  be a function returning a list of files. Explicit lists and org-style
  list-file values work as before.
- **Renamed option**: `consult-org-headings-narrow-key` is renamed to
  `consult-notes-org-headings-narrow-key`; the old name survives as an
  obsolete alias.

### General

- **Dependencies**: the `s` and `dash` libraries are no longer required;
  built-in equivalents are used throughout.
- **Removed dead code**: `consult-notes-default-format` and
  `consult-notes-file-action` (defined but never read),
  `consult-notes-denote--blinks` (broken and unused), and
  `consult-notes--string-matches` (obsoleted by the annotation fix).
- **Byte-compilation**: all files compile without warnings (docstring widths,
  free variables, quoting, faces group).

## 0.8

### Org-Roam

- **Configurable open function**: New `consult-notes-org-roam-open-function`
  defcustom (default `org-roam-node-visit`). Set to `org-roam-node-open` to
  restore previous window behavior. (#80)
- **New node on match failure**: When input does not match an existing node,
  `consult-notes` now creates a new org-roam node via `org-roam-capture-`,
  matching the behavior of `org-roam-node-find` and the denote backend. (#80)
- **Respect org-roam-node-display-template**: consult-notes no longer overrides
  `org-roam-node-display-template`. Customize that variable directly for display
  control. (#79)
- **Duplicate title handling**: Nodes with identical titles are disambiguated
  with an ID suffix rather than raising an error. (#19)
- **Empty title fallbacks**: Nodes with empty or whitespace-only titles fall
  back to filename or node ID.
- **Runtime annotation lookup**: Annotation functions are wrapped in lambdas
  so that `consult-notes-org-roam-annotate-function` changes take effect
  without re-enabling the mode.

### Denote

- **Fixed title column width**: New `consult-notes-denote-title-width` defcustom.
  When set to a number, titles are truncated or padded to that exact width for
  consistent column alignment. When nil (default), auto-computes from the widest
  title. (#82)
- **Configurable file listing**: `consult-notes-denote-files-function` controls
  which files are listed (all files, denote-only files, or a custom regex).
- **Configurable keyword display**: `consult-notes-denote-display-keywords-function`,
  `consult-notes-denote-display-keywords-indicator`, and
  `consult-notes-denote-display-keywords-width` control keyword formatting.
- **Configurable directory display**: `consult-notes-denote-display-dir-function`
  controls how directory names appear.

### General

- **Exclude dailies**: New `consult-notes-org-roam-exclude-dailies` option to
  hide org-roam dailies from `consult-notes` while keeping them searchable via
  `consult-notes-search-in-all-notes`. (#58)
- **Hidden sources**: `consult-notes-file-dir-sources` entries accept `:hidden t`
  to hide a source from the default list while keeping it accessible via its
  narrowing key.
- **UTF-8 encoding**: Added encoding declarations to all source files. (#75)
- **Embark + org-headings**: Fixed embark integration for org-headings source. (#48)
