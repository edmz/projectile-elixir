;;; projectile-elixir.el --- Minor mode for Elixir projects based on projectile-mode

;; Copyright (C) 2013, 2014 edmz, Adam Sokolnickim

;; Author:            Eduardo Dmz <edmz@gmail>
;; URL:               https://github.com/edmz/projectile-elixir
;; Version:           0.1.0
;; Keywords:          elixir, projectile
;; Package-Requires:  ((projectile "1.0.0-cvs") (f "0.13.0"))

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; This mode is *heavily* based on the great work done in
;; projectile-rails by Adam Sokolnickim.
;;
;; It is a work in progress. Alpha-quality.
;;
;; To make it start alongside projectile-mode:
;;
;;    (add-hook 'projectile-mode-hook 'projectile-elixir-on)
;; 
;;; Code:

(require 'projectile)
(require 'f)

(defgroup projectile-elixir nil
  "Elixir mode based on projectile"
  :prefix "projectile-elixir-"
  :group 'projectile)

(defcustom projectile-elixir-mix-keywords
  '("deps" "project")
  "List of keywords to highlight for mix.exs file"
  :group 'projectile-elixir
  :type '(repeat string))

(defcustom projectile-elixir-test-keywords
  '("ExUnit")
  "List of keywords to highlight for tests"
  :group 'projectile-elixir
  :type '(repeat string))

(defcustom projectile-elixir-base-keywords
  '("alias_attribute" "with_options" "delegate")
  "List of keywords to highlight for all `projectile-elixir-mode' buffers"
  :group 'projectile-elixir
  :type '(repeat string))


(defcustom projectile-elixir-font-lock-face-name 'font-lock-keyword-face
  "Face to be used for higlighting Elixir the keywords")


(defcustom projectile-elixir-errors-re
  "\\([0-9A-Za-z@_./\:-]+\\.rb\\):?\\([0-9]+\\)?"
  "The regex used to find errors with file paths."
  :group 'projectile-elixir
  :type 'string)

(defcustom projectile-elixir-expand-snippet t
  "If not nil newly created buffers will be pre-filled with class skeleton.")

(defcustom projectile-elixir-add-keywords t
  "If not nil the elixir keywords will be font locked in the mode's bufffers.")

(defcustom projectile-elixir-keymap-prefix (kbd "C-c x")
  "`projectile-elixir-mode' keymap prefix."
  :group 'projectile-elixir
  :type 'string)


(defcustom projectile-elixir-discover-bind "s-r"
  "The :bind option that will be passed `discover-add-context-menu' if available.")


(defmacro projectile-elixir-with-root (body-form)
  `(let ((default-directory (projectile-elixir-root)))
     ,body-form))

(defmacro projectile-elixir-find-current-resource (dir re fallback)
  "RE will be the argument to `s-lex-format'.

The binded variables are \"singular\" and \"plural\"."
  `(let* ((singular (projectile-elixir-current-resource-name))          
          (abs-current-file (buffer-file-name (current-buffer)))
          (current-file (if abs-current-file
                            (file-relative-name abs-current-file
                                                (projectile-project-root))))
          (files (--filter
                  (and (string-match-p (s-lex-format ,re) it)
                       (not (string= current-file it)))
                  (projectile-dir-files (projectile-expand-root ,dir)))))
     (if (null files)
         (funcall ,fallback)
       (projectile-elixir-goto-file
        (if (= (length files) 1)
            (-first-item files)
          (projectile-completing-read "Which exactly: " files))))))


(defun projectile-elixir-highlight-keywords (keywords)
  "Highlight the passed KEYWORDS in current buffer."
  (font-lock-add-keywords
   nil
   (list (list
          (concat "\\(^\\|[^_:.@$]\\|\\.\\.\\)\\b"
                  (regexp-opt keywords t)
                  "\\_>")
          (list 2 projectile-elixir-font-lock-face-name)))))

(defun projectile-elixir-add-keywords-for-file-type ()
  "Apply extra font lock keywords specific to models, controllers etc."
  (loop for (re keywords) in `(("mix\\.exs$"   ,projectile-elixir-mix-keywords)
                               ("test/.+\\.ex$" ,projectile-elixir-test-keywords))
        do (when (and (buffer-file-name) (string-match-p re (buffer-file-name)))
             (projectile-elixir-highlight-keywords
              (append keywords projectile-elixir-base-keywords)))))

(defun projectile-elixir-choices (dirs)
  "Uses `projectile-dir-files' function to find files in directories.

The DIRS is list of lists consisting of a directory path and regexp to filter files from that directory.
Returns a hash table with keys being short names and values being relative paths to the files."
  (let ((hash (make-hash-table :test 'equal)))
    (loop for (dir re) in dirs do
          (loop for file in (projectile-dir-files (projectile-expand-root dir)) do
                (when (string-match re file)
                  (puthash (match-string 1 file) file hash))))
    hash))

(defun projectile-elixir-hash-keys (hash)
  (let (keys)
    (maphash (lambda (key value) (setq keys (cons key keys))) hash)
    keys))

(defun projectile-elixir-find-resource (prompt dirs)
  (let ((choices (projectile-elixir-choices dirs)))
    (projectile-elixir-goto-file
     (gethash (projectile-completing-read prompt (projectile-elixir-hash-keys choices)) choices))))


(defun projectile-elixir-find-module ()
  (interactive)
  (projectile-elixir-find-resource "module: " '(("lib/" "lib/\\(.+\\)\\.ex$"))))


(defun projectile-elixir-find-test ()
  (interactive)
  (projectile-elixir-find-resource "test: " '(("test/" "test/\\(.+\\)_test\\.exs$"))))

(defun projectile-elixir-find-current-module ()
  (interactive)
  (projectile-elixir-find-current-resource "lib/"
                                          "/${singular}\\.ex$"
                                          'projectile-elixir-find-module))


(defun projectile-elixir-find-current-test ()
  (interactive)
  (projectile-find-test-file))


(defun projectile-elixir-current-resource-name ()
  "Returns a resource name extracted from the name of the currently visiting file"
  (let ((file-name (buffer-file-name)))
    (if file-name
        (singularize-string
         (loop for re in '("lib/\\(?:.+/\\)*\\(.+\\)\\.ex")
               until (string-match re file-name)
               finally return (match-string 1 file-name))))))

(defun projectile-elixir-list-entries (fun dir)
  (--map
   (substring it (length (concat (projectile-elixir-root) dir)))
   (funcall fun (projectile-expand-root dir))))

(defun projectile-elixir-iex-s-mix ()
  "Runs elixr-mode-iex with '-S mix' as parameters."
  (projectile-elixir-with-root
   (elixir-mode-iex "-S mix")))


(defun projectile-elixir-root ()
  "Return elixir root directory if this file is a part of an Elixir project else nil."
  (ignore-errors
    (let ((root (projectile-project-root)))
      (when (file-exists-p (expand-file-name "mix.exs" root))
        root))))


(defun projectile-elixir-expand-snippet-maybe ()
  (when (and (fboundp 'yas-expand-snippet)
             (and (buffer-file-name) (not (file-exists-p (buffer-file-name))))
             (s-blank? (buffer-string))
             (projectile-elixir-expand-corresponding-snippet))))

(defun projectile-elixir--expand-snippet-for-module (last-part)
  (let ((parts (projectile-elixir-classify (match-string 1 name))))
    (format
     (concat
      (s-join "" (--map (s-lex-format "defmodule ${it}\n") (butlast parts)))
      last-part
      (s-join "" (make-list (1- (length parts)) "\nend")))
     (-last-item parts)))
  )

(defun projectile-elixir-expand-corresponding-snippet ()
  (let ((name (buffer-file-name)))
    (yas-expand-snippet
     (cond ((string-match "lib/\\(.+\\)\\.ex$" name)
            (format
             "defmodule %s do\n$1\nend"
             (s-join "::" (projectile-elixir-classify (match-string 1 name)))))
           ((string-match "spec/[^/]+/\\(.+\\)_spec\\.rb$" name)
            (format
             "require \"spec_helper\"\n\ndescribe %s do\n$1\nend"
             (s-join "::" (projectile-elixir-classify (match-string 1 name)))))
           ((string-match "app/models/\\(.+\\)\\.rb$" name)
            (format
             "class %s < ${1:ActiveRecord::Base}\n$2\nend"
             (s-join "::" (projectile-elixir-classify (match-string 1 name)))))
           ((string-match "lib/\\(.+\\)\\.ex$" name)
            (projectile-elixir--expand-snippet-for-module "${1:module} %s\n$2\nend"))
           ((string-match "app/\\(?:[^/]+\\)/\\(.+\\)\\.rb$" name)
            (projectile-elixir--expand-snippet-for-module "${1:class} %s\n$2\nend"))))))

(defun projectile-elixir-classify (name)
  "Accepts a filepath, splits it by '/' character and classifieses each of the element"
  (--map (replace-regexp-in-string "_" "" (upcase-initials it)) (split-string name "/")))

(defun projectile-elixir-declassify (name)
  "Converts passed string to a relative filepath."
  (let ((case-fold-search nil))
    (downcase
     (replace-regexp-in-string
      "::" "/"
      (replace-regexp-in-string
       " " "_"
       (replace-regexp-in-string
        "\\([a-z]\\)\\([A-Z]\\)" "\\1 \\2" name))))))



(defun projectile-elixir-sanitize-and-goto-file (dir name &optional ext)
  "Calls `projectile-elixir-goto-file' with passed arguments sanitizing them before."
  (projectile-elixir-goto-file
   (concat
    (projectile-elixir-sanitize-dir-name dir) (projectile-elixir-declassify name) ext)))

(defun projectile-elixir-goto-file (filepath)
  "Finds the FILEPATH after expanding root."
  (projectile-elixir-ff (projectile-expand-root filepath)))

(defun projectile-elixir-goto-file-at-point ()
  "Tries to find file at point"
  (interactive)
  (let ((name (projectile-elixir-name-at-point))
        (line (projectile-elixir-current-line))
        (case-fold-search nil))
    (cond 
          ((string-match-p "\\_<require_relative\\_>" line)
           (projectile-elixir-ff (expand-file-name (concat (thing-at-point 'filename) ".rb"))))

          ((string-match-p "\\_<require\\_>" line)
           (projectile-elixir-goto-gem (thing-at-point 'filename)))

          ((not (string-match-p "^[A-Z]" name))
           (projectile-elixir-sanitize-and-goto-file "app/models/" (singularize-string name) ".rb"))

          ((string-match-p "^[A-Z]" name)
           (loop for dir in (-concat
                             (--map
                              (concat "app/" it)
                              (projectile-elixir-list-entries 'f-directories "app/"))
                             '("lib/"))
                 until (projectile-elixir-sanitize-and-goto-file dir name ".rb"))))))



(defun projectile-elixir--ignore-buffer-p ()
  "Returns t if `projectile-elixir' should not be enabled for the current buffer"
  (string-match-p "\\*\\(Minibuf-[0-9]+\\|helm mini\\)\\*" (buffer-name)))



(defun projectile-elixir-goto-mix-exs ()
  (interactive)
  (projectile-elixir-goto-file "mix.exs"))

(defun projectile-elixir-goto-config-exs ()
  (interactive)
  (projectile-elixir-goto-file "config/config.exs"))

(defun projectile-elixir-goto-test-helper ()
  (interactive)
  (projectile-elixir-goto-file "test/test_helper.exs"))

(defun projectile-elixir-ff (path &optional ask)
  "Calls `find-file' function on PATH when it is not nil and the file exists.

If file does not exist and ASK in not nil it will ask user to proceed."
  (if (or (and path (file-exists-p path))
          (and ask (yes-or-no-p (s-lex-format "File does not exists. Create a new buffer ${path} ?"))))
      (find-file path)))

(defun projectile-elixir-name-at-point ()
  (projectile-elixir-sanitize-name (symbol-name (symbol-at-point))))

(defun projectile-elixir-filename-at-point ()
  (projectile-elixir-sanitize-name (thing-at-point 'filename)))


(defun projectile-elixir--generate-buffer-make-buttons (buffer exit-code)
  (with-current-buffer buffer
    (goto-char 0)
    (while (re-search-forward projectile-elixir-generate-filepath-re (max-char) t)
      (make-button
       (match-beginning 1)
       (match-end 1)
       'action
       'projectile-elixir-generate-ff
       'follow-link
       t))))


(defun projectile-elixir-generate-ff (button)
  (find-file (projectile-expand-root (button-label button))))

(defun projectile-elixir-sanitize-name (name)
  (when (or
         (and (s-starts-with? "'" name) (s-ends-with? "'" name))
         (and (s-starts-with? "\"" name) (s-ends-with? "\"" name)))
    (setq name (substring name 1 -1)))
  (when (s-starts-with? "./" name)
    (setq name (substring name 2)))
  (when (or (s-starts-with? ":" name) (s-starts-with? "/" name))
    (setq name (substring name 1)))
  (when (s-ends-with? "," name)
    (setq name (substring name 0 -1)))
  name)

(defun projectile-elixir-sanitize-dir-name (name)
  (if (s-ends-with? "/" name) name (concat name "/")))

(defun projectile-elixir-current-line ()
  (save-excursion
    (let (beg)
      (beginning-of-line)
      (setq beg (point))
      (end-of-line)
      (buffer-substring-no-properties beg (point)))))

(defvar projectile-elixir--version "0.1.0")

(defvar projectile-elixir-mode-goto-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "f") 'projectile-elixir-goto-file-at-point)
    (define-key map (kbd "m") 'projectile-elixir-goto-mix-exs)
    (define-key map (kbd "c") 'projectile-elixir-goto-config-exs)   
    (define-key map (kbd "t") 'projectile-elixir-goto-test-helper)
    map)
  "A goto map for `projectile-elixir-mode'.")
(fset 'projectile-elixir-mode-goto-map projectile-elixir-mode-goto-map)

(defvar projectile-elixir-mode-run-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "c") 'projectile-elixir-iex-s-mix)      
    map)
  "A run map for `projectile-elixir-mode'.")
(fset 'projectile-elixir-mode-run-map projectile-elixir-mode-run-map)

(defvar projectile-elixir-command-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "m") 'projectile-elixir-find-module)
    (define-key map (kbd "M") 'projectile-elixir-find-current-module)    

    (define-key map (kbd "t") 'projectile-elixir-find-test)
    (define-key map (kbd "P") 'projectile-elixir-find-current-test)
   
    (define-key map (kbd "r") 'projectile-elixir-iex-s-mix)   
   
    (define-key map (kbd "RET") 'projectile-elixir-goto-file-at-point)

    (define-key map (kbd "g") 'projectile-elixir-mode-goto-map)
    (define-key map (kbd "!") 'projectile-elixir-mode-run-map)
    map)
  "Keymap after `projectile-elixir-keymap-prefix'.")
(fset 'projectile-elixir-command-map projectile-elixir-command-map)

(defvar projectile-elixir-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map projectile-elixir-keymap-prefix 'projectile-elixir-command-map)
    map)
  "Keymap for `projectile-elixir-mode'.")

(easy-menu-define projectile-elixir-menu projectile-elixir-mode-map
  "Menu for `projectile-elixir-mode'."
  '("Elixir Project"
    ["Find module"              projectile-elixir-find-module]
    ["Find test"                projectile-elixir-find-test]
    "--"
    ["Go to file at point"      projectile-elixir-goto-file-at-point]
    "--"
    ["Go to Mix.exs"            projectile-elixir-goto-mix-exs]
    ["Go to config.exs"         projectile-elixir-goto-config-exs]   
    ["Go to test helper"        projectile-elixir-goto-test-helper]
    "--"
    ["Go to current module"     projectile-elixir-find-current-module]
    ["Go to current test"       projectile-elixir-find-current-test]
    ;;"--"
    ;;["Run iex -S mix"           projectile-elixir-iex-s-mix]
    ))

;;;###autoload
(define-minor-mode projectile-elixir-mode
  "Elixir mode based on projectile"
  :init-value nil
  :lighter " ElixirProj"
  (when projectile-elixir-mode
    (and projectile-elixir-expand-snippet (projectile-elixir-expand-snippet-maybe))
    (and projectile-elixir-add-keywords (projectile-elixir-add-keywords-for-file-type))
    ))

;;;###autoload
(defun projectile-elixir-show-version ()
  "Elixir mode print version."
  (interactive)
  (message (format "projectile-elixir v%s" projectile-elixir--version)))

;;;###autoload
(defun projectile-elixir-on ()
  "Enable `projectile-elixir-mode' minor mode if this is a elixir project."
  (when (and
         (not (projectile-elixir--ignore-buffer-p))
         (projectile-elixir-root))
    (projectile-elixir-mode +1)))

(defun projectile-elixir-off ()
  "Disable `projectile-elixir-mode' minor mode."
  (projectile-elixir-mode -1))


(when (functionp 'discover-add-context-menu)

  (defun projectile-elixir--discover-find-submenu ()
    (interactive)
    (call-interactively
     (discover-get-context-menu-command-name 'projectile-elixir-find)))

  (defun projectile-elixir--discover-goto-submenu ()
    (interactive)
    (call-interactively
     (discover-get-context-menu-command-name 'projectile-elixir-goto)))

  (defun projectile-elixir--discover-run-submenu ()
    (interactive)
    (call-interactively
     (discover-get-context-menu-command-name 'projectile-elixir-run)))

  (discover-add-context-menu
   :context-menu '(projectile-elixir-mode
                   (description "Mode for Elixir projects")
                   (actions
                    ("Available"
                     ("f" "find resources"   projectile-elixir--discover-find-submenu)
                     ("g" "goto resources"   projectile-elixir--discover-goto-submenu)
                     ("r" "run and interact" projectile-elixir--discover-run-submenu))))
   :bind projectile-elixir-discover-bind
   :mode 'projectile-elixir
   :mode-hook 'projectile-elixir-mode-hook)

  (discover-add-context-menu
   :context-menu '(projectile-elixir-find
                   (description "Find resources")
                   (actions
                    ("Find a resource"
                     ("m" "model"       projectile-elixir-find-module)
                     ("t" "test"        projectile-elixir-find-test))
                    ("Find an associated resource"
                     ("M" "module"      projectile-elixir-find-current-module)
                     ("T" "test"        projectile-elixir-find-current-test))))
   :bind "") ;;accessible only from the main context menu

  (discover-add-context-menu
   :context-menu '(projectile-elixir-goto
                   (description "Go to a specific file")
                   (actions
                    ("Go to"
                     ("f" "file at point" projectile-elixir-goto-file-at-point)
                     ("m" "Mix.exs"       projectile-elixir-goto-mix-exs)
                     ("c" "config.exs"    projectile-elixir-goto-config-exs)                    
                     ("t" "test helper"   projectile-elixir-goto-test-helper))))
   :bind "") ;;accessible only from the main context menu

  (discover-add-context-menu
   :context-menu '(projectile-elixir-run
                   (description "Run and interact")
                   (actions
                    ("Run external command"
                     ("m" "mix"           projectile-elixir-mix)
                     ("c" "iex-mix"       projectile-elixir-iex-s-mix))
                    ("Interact"
                     ("x" "extract region" projectile-elixir-extract-region))))
   :bind "") ;;accessible only from the main context menu
  )

  (provide 'projectile-elixir)
  

;;; projectile-elixir.el ends here
