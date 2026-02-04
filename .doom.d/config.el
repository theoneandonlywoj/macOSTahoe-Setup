;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

;; Force English locale for dates/times (e.g. day names like "Tuesday" in journal filenames and modeline)
(setq system-time-locale "C")

;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "Wojciech Orzechowski"
      user-mail-address "theoneandonlywoj@gmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; Start Emacs in fullscreen
(add-to-list 'initial-frame-alist '(fullscreen . maximized))

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; Force line numbers on in all programming/text modes
(global-display-line-numbers-mode t)

;; Show raw org links (i.e. don't hide [[url][desc]] by default)
(setq org-link-descriptive nil)

;; Highlight current line
(global-hl-line-mode t)

;; Better scrolling
(pixel-scroll-precision-mode 1)
(setq scroll-margin 5
      scroll-conservatively 101)

;; Editing
(map! :leader
      :desc "Delete current line"
      "e d d" #'kill-whole-line)

;; Window management and automac focus
;; Automatically focus the new window after splitting
(defun my/split-window-right-and-focus ()
  "Split the window vertically and move focus to the new one."
  (interactive)
  (split-window-right)
  (other-window 1))

(defun my/split-window-below-and-focus ()
  "Split the window horizontally and move focus to the new one."
  (interactive)
  (split-window-below)
  (other-window 1))

;; Override Doom's default window split keybindings
(map! :leader
      (:prefix ("w" . "windows")
       :desc "Split window right and focus" "v" #'my/split-window-right-and-focus
       :desc "Split window below and focus" "s" #'my/split-window-below-and-focus))

;; Remember cursor position in files
(save-place-mode 1)

;; Typing replaces selected text
(delete-selection-mode t)

;; Display time and battery status (if applicable)
(display-time-mode 1)
(display-battery-mode 1)

;; Always split vertically to the right and horizontally below
(setq split-width-threshold 0)   ;; Force vertical splits to go to the right
(setq split-height-threshold nil) ;; Never split horizontally unless explicitly


;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
;; (setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; Second Brain with org-mode
;; 1. Directory Setup
(dolist (dir '("~/Desktop/Repos/Second-Brain/1.Notes"
               "~/Desktop/Repos/Second-Brain/2.Templates"
               "~/Desktop/Repos/Second-Brain/3.Journal"
               "~/Desktop/Repos/Second-Brain/4.Archived"))
  (unless (file-directory-p dir)
    (make-directory dir t)))

;; 2. Org-roam Setup
(use-package! org-roam
  :init
  (setq org-roam-v2-ack t) ;; if using org-roam v2
  :custom
  (org-roam-directory "~/Desktop/Repos/Second-Brain/1.Notes")
  (org-roam-db-location "~/Desktop/Repos/Second-Brain/org-roam.db")
  :config
  (org-roam-db-autosync-enable))

;; 3. Org-roam UI Setup
(use-package! org-roam-ui
  :after org-roam
  :hook (org-roam . org-roam-ui-mode)
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t))

;; 4. Org-roam Capture Templates
;; Setting the Journal Directory
(setq org-roam-dailies-directory "~/Desktop/Repos/Second-Brain/3.Journal/")

;; 4. Org-roam Capture Templates
(setq org-roam-capture-templates
      '(("j" "Daily Journal" plain
         (file+head "~/Desktop/Repos/Second-Brain/3.Journal/%<%Y-%m-%d-%A>.org"
                    "#+TITLE: Journal: %<%Y-%m-%d-%A>\n#+AUTHOR: Wojciech Orzechowski (theoneandonlywoj@gmail.com)\n#+DATE: %U\n\n")
         :unnarrowed t)))

;; 5. Interactive Template Note Creation
(defun my/org-roam-capture-from-template ()
  "Create a new Org-roam note by selecting a template from ~/Desktop/Repos/Second-Brain/2.Templates.
Prompts for title and initial file tags (with completion from existing tags)."
  (interactive)
  (let* ((template-dir "~/Desktop/Repos/Second-Brain/2.Templates/")
         (templates (directory-files template-dir t ".*\\.org$"))
         (template-file (completing-read "Choose template: " templates))
         (title (read-string "Note Title: "))
         ;; Collect all existing tags from org-roam files
         (existing-tags (delete-dups
                         (org-roam-db-query
                          [:select [tag]
                           :from tags])))
         ;; Flatten tag list (they're stored as vectors)
         (tag-list (mapcar #'car existing-tags))
         (tags (completing-read-multiple
                "Tags (comma-separated, TAB to complete): "
                tag-list))
         (tags-string (mapconcat #'identity tags " "))
         ;; Generate slug and paths
         (slug (org-roam-node-slug (org-roam-node-create :title title)))
         (target-dir "~/Desktop/Repos/Second-Brain/1.Notes/")
         (target-file (concat (file-name-as-directory target-dir) slug ".org")))

    ;; Ensure target directory exists
    (unless (file-directory-p target-dir)
      (make-directory target-dir t))

    ;; Copy template into target file
    (copy-file template-file target-file t)

    ;; Replace placeholders and insert tags
    (with-current-buffer (find-file target-file)
      (goto-char (point-min))
      (while (re-search-forward "${title}" nil t)
        (replace-match title))
      (goto-char (point-min))
      (while (re-search-forward "${author}" nil t)
        (replace-match "Wojciech Orzechowski"))
      (goto-char (point-min))
      (while (re-search-forward "${date}" nil t)
        (replace-match (format-time-string "%Y-%m-%d %H:%M")))
      ;; Add or update FILETAGS line
      (goto-char (point-min))
      (if (re-search-forward "^#\\+FILETAGS:" nil t)
          (replace-match (format "#+FILETAGS: %s" tags-string))
        (re-search-forward "^#\\+TITLE:" nil t)
        (forward-line 1)
        (insert (format "#+FILETAGS: %s\n" tags-string))))

    ;; Finalize and sync with Org-roam
    (find-file target-file)
    (org-roam-db-sync)
    (message "Created note: %s" target-file)))

;; 6. Interactive Template Journal Note Creation
(defun my/org-roam-daily-from-template ()
  "Create an Org-roam daily journal note from a selected template.
Prompts for whether to create the note for today, tomorrow, or N days ahead.
Templates are in ~/Desktop/Repos/Second-Brain/2.Templates/.
Result is saved in ~/Desktop/Repos/Second-Brain/3.Journal/."
  (interactive)
  (let* ((template-dir "~/Desktop/Repos/Second-Brain/2.Templates/")
         (journal-dir "~/Desktop/Repos/Second-Brain/3.Journal/")
         (choice (read-number "Create journal for: [1] Today  [2] Tomorrow  [n] Days ahead → " 1))
         (offset (cond
                  ((= choice 1) 0)
                  ((= choice 2) 1)
                  (t choice)))
         ;; Calculate the target date
         (target-time (time-add (current-time) (days-to-time offset)))
         (filename (format-time-string "%Y-%m-%d-%A.org" target-time))
         (file-path (concat (file-name-as-directory journal-dir) filename))
         (title (format-time-string "%Y-%m-%d (%A)" target-time))
         (template-file (completing-read "Choose journal note template: "
                                         (directory-files template-dir t ".*\\.org$"))))

    ;; Ensure journal directory exists
    (unless (file-directory-p journal-dir)
      (make-directory journal-dir t))

    ;; Copy template and fill placeholders
    (copy-file template-file file-path t)
    (with-current-buffer (find-file file-path)
      (goto-char (point-min))
      (while (re-search-forward "${title}" nil t)
        (replace-match title))
      (goto-char (point-min))
      (while (re-search-forward "${author}" nil t)
        (replace-match "Wojciech Orzechowski"))
      (goto-char (point-min))
      (while (re-search-forward "${date}" nil t)
        (replace-match (format-time-string "%Y-%m-%d" target-time)))
      (save-buffer))

    ;; Sync and open
    (org-roam-db-sync)
    (find-file file-path)
    (message "Created journal note: %s" file-path)))

;; 7. Archive Note Function
(defun my/org-roam-archive-note ()
  "Archive the current Org-roam note by moving it
  to 4.Archived and updating Org-roam DB."
  (interactive)
  (let* ((current (buffer-file-name))
         (archive-dir "~/Desktop/Repos/Second-Brain/4.Archived/"))

    ;; Ensure archive directory exists
    (unless (file-directory-p archive-dir)
      (make-directory archive-dir t))

    (if (not current)
        (message "No file to archive")
      (let ((new-location (concat (file-name-as-directory archive-dir)
                                  (file-name-nondirectory current))))

        ;; Close buffer before moving
        (kill-buffer)

        ;; Move file to archive folder
        (rename-file current new-location 1)

        ;; Update Org-roam DB
        (org-roam-db-sync)

        (message "Archived note to %s" new-location)))))

;;  8. Keybindings
(map! :leader
      :desc "New note from template"
      "n p" #'my/org-roam-capture-from-template
      :desc "Daily journal note"
      "n j" #'my/org-roam-daily-from-template
      :desc "Archive current note"
      "n d" #'my/org-roam-archive-note)

(defun my/org-insert-example-block ()
  "Insert an Org example block at point."
  (interactive)
  (insert "#+BEGIN_EXAMPLE\n\n#+END_EXAMPLE")
  (forward-line -1))

(map! :leader
      :desc "Insert Org example block"
      "i b" #'my/org-insert-example-block)

(defun my/org-insert-elixir-code-block ()
  "Insert an Elixir block at point."
  (interactive)
  (insert "#+BEGIN_SRC elixir\n\n#+END_SRC")
  (forward-line -1))

(map! :leader
      :desc "Insert Elixir code block"
      "i c e" #'my/org-insert-elixir-code-block)

;; 9. Styling
;; Nicer checkboxes
(after! org
  (add-hook 'org-mode-hook
            (lambda ()
              (push '("[ ]" . "◯") prettify-symbols-alist)  ;; Bigger empty
              (push '("[X]" . "⬤") prettify-symbols-alist)  ;; Bigger checked
              (push '("[-]" . "◑") prettify-symbols-alist)  ;; Bigger partial
              (prettify-symbols-mode)))

  (setq prettify-symbols-unprettify-at-point 'right-edge)

  (custom-set-faces!
   '(org-checkbox :height 1.2)))
