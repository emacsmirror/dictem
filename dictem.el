(defgroup edict nil
  "Client for accessing the DICT server."
  :group 'help
  :group 'hypermedia
  )

(defcustom edict-server "dict.org"
  "The DICT server"
  :group 'edict
  :type 'string
  )

(defcustom edict-port "2628"
  "The port of the DICT server"
  :group 'edict
  :type 'string
  )

(defcustom edict-client-prog "dict"
  "The command line DICT client.
edict accesses DICT server through this executable."
  :group 'edict
  :type 'string
  )

(defvar edict-strategy-list
  '(
    ("."         nil)
;    ("word"    nil)
    ("exact"     nil)
    ("prefix"    nil)
    ("substring" nil)
    ("suffix"  nil)
    ("re"      nil)
    ("regexp"  nil)
    ("soundex" nil)
    ("lev"     nil)
    )
  )

(defvar edict-database-list
  '(
    ( "*"   nil )
    ( "elements" nil )
    ( "web1913" nil )
    ( "wn" nil )
    ( "gazetteer" nil )
    ( "jargon" nil )
    ( "foldoc" nil )
    ( "easton" nil )
    ( "hitchcock" nil )
    ( "devils" nil )
    ( "world02" nil )
    ( "vera" nil )
    )
  )

(defcustom edict-default-strategy "."
  "The default search strategy."
  :group 'edict
  :group 'string
  )

(defcustom edict-default-database "*"
  "The default database name."
  :group 'edict
  :group 'string
  )

(defvar edict-strategy-history nil)
(defvar edict-database-history nil)
(defvar edict-query-history nil)
(defvar edict-last-database
  "Last used database name"
  "*"
  )

(defvar edict-last-strategy
  "Last used strategy name"
  "."
  )

(defvar edict-mode-map
  nil
  "Keymap for edict mode")

(defun list2alist (list)
  (if
      list
      (cons
       (list (car list) nil)
       (list2alist (cdr list))
       )
    nil
    )
  )

(defun edict-select (prompt alist default history)
  (let
      ((completion-ignore-case t))
    (completing-read
     (concat prompt " (" default "): ")
     alist
     nil
     t
     nil
     history
     default
     )
    )
  )

(defun get-first-token ()
  (let
      ((str (thing-at-point 'line)))
    (if
	(string-match "^ [^ ][^ ]*" str )
	(list (substring str ( + (match-beginning 0) 1) (match-end 0)))
      )
    )
  )

(defun get-first-tokens-from-temp-buffer ()
;    (switch-to-buffer "*dict-temp*")
  (set-buffer "*dict-temp*")
  (beginning-of-buffer)
  (let ((list-of-first-tokens nil )) ;(get-first-tokens)))
    (while (= (forward-line 1) 0)
      (setq list-of-first-tokens (append (get-first-token) list-of-first-tokens))
      )
    list-of-first-tokens
    )
  )

(defun edict-set-strategies ()
  "Obtain strategy list from a DICT server
and sets edict-strategy-list variable."
  (interactive)
  (if
      (eq 0 (call-process "dict" nil "*dict-temp*" nil "-P" "-" "-S" "-h" edict-server "-p" edict-port))
      (setq edict-strategy-list
	    (cons
	     (list "." nil)
	     (nreverse (list2alist (get-first-tokens-from-temp-buffer) ) )
	     )
	    )
    )
  (kill-buffer "*dict-temp*")
  )

(defun edict-set-databases ()
  "Obtain database list from a DICT server
and sets edict-database-list variable."
  (interactive)
  (if
      (eq 0 (call-process "dict" nil "*dict-temp*" nil "-P" "-" "-D" "-h" edict-server "-p" edict-port))
      (setq edict-database-list
	    (cons
	     (list "*" nil)
	     (nreverse (list2alist (get-first-tokens-from-temp-buffer)))
	     )
	    )
    )
  (kill-buffer "*dict-temp*")
  )

(defun edict-help ()
  "Display a edict help"
  (interactive)
  (describe-function 'edict-mode))

(defun edict-select-strategy (&optional default-strat)
  "Switches to minibuffer and ask user
to enter a search strategy."
  (interactive)

  (setq edict-last-strategy
	(edict-select
	 "strategy"
	 edict-strategy-list
	 (if
	     default-strat
	     default-strat
	   (if edict-strategy-history
	       (car edict-strategy-history)
	     "exact"
	     )
	   )
	 'edict-strategy-history
	 )
	)
  )

(defun edict-select-database (&optional default-db)
  "Switches to minibuffer and ask user
to enter a database name."
  (interactive)

  (setq edict-last-database
	(edict-select
	 "db"
	 edict-database-list
	 (if
	     default-db
	     default-db
	   (if edict-database-history
	       (car edict-database-history)
	     "*"
	     )
	   )
	 'edict-database-history
	 )
	)
  )

(defun edict-read-query (&optional default-query)
  "Switches to minibuffer and ask user
to enter a query."
  (interactive)

  (read-string
   (concat "query:(" default-query ") ")
   nil
   'edict-query-history
   default-query
   t)
  )

(defun edict-replace-spaces (str)
  (while (string-match "  +" str)
    (setq str (replace-match " " t t str)))
  (if (string-match "^ +" str)
      (setq str (replace-match "" t t str)))
  (if (string-match " +$" str)
      (setq str (replace-match "" t t str)))
  str
  )

;(edict-replace-spaces " qwe   ertrwww   ")

(defface edict-reference-define-face
  '((((type x)
      (class color)
      (background dark))
     (:foreground "cyan"))
    (((type tty)
      (class color)
      (background dark))
     (:foreground "cyan"))
    (((class color)
      (background light))
     (:foreground "blue"))
    (t
     (:underline t)))

  "The face that is used for displaying a reference to
a phrase in a DEFINE search."
  :group 'edict)

(defface edict-reference-m1-face
  '((((type x)
      (class color)
      (background dark))
     (:foreground "cyan"))
    (((type tty)
      (class color)
      (background dark))
     (:foreground "cyan"))
    (((class color)
      (background light))
     (:foreground "blue"))
    (t
     (:underline t)))

  "The face that is used for displaying a reference to
a phrase in a MATCH search."
  :group 'edict)

(defface edict-reference-m2-face
  nil

  "The face that is used for displaying a reference to
a single word in a MATCH search."
  :group 'edict)

(defun edict-define-on-click (event)
  "Is called upon clicking the link."
  (interactive "@e")

  (mouse-set-point event)
  (let* (
	 (properties (text-properties-at (point)))
	 (word (plist-get properties 'link-data)))
    (if word
	(edict-search edict-last-database nil word 'edict-define-base)
      )
    )
  )

(defun edict-define-with-db-on-click (event)
  "Is called upon clicking the link."
  (interactive "@e")

  (mouse-set-point event)
  (let* (
	 (properties (text-properties-at (point)))
	 (word (plist-get properties 'link-data)))
    (if word
	(edict-search (edict-select-database) nil word 'edict-define-base)
      )
    )
  )

(defun link-create-link (start end face function &optional data help)
  "Create a link in the current buffer starting from `start' going to `end'.
The `face' is used for displaying, the `data' are stored together with the
link.  Upon clicking the `function' is called with `data' as argument."
  (let ((properties `(face ,face
	              mouse-face highlight
		      link t
		      link-data ,data)
;		      help-echo ,help
;		      link-function ,function)
		    )
	)
    (remove-text-properties start end properties)
    (add-text-properties start end properties)))

(defun edict-new-search (word &optional all)
;  (interactive)
  (edict-search
   edict-last-database
   "exact"
   word
   'edict-define-base)
  )

(defun edict-colorit-define ()
;  (interactive)
  (let ((regexp "\\({\\)\\([^}]*\\)\\(}\\)"))
    (beginning-of-buffer)
    (while (< (point) (point-max))
      (if (search-forward-regexp regexp nil t)
	  (progn
	    (let* (
		  (match-length (- (match-end 2) (match-beginning 2)))
		  (match-string (match-string 2))
		  (match-start (match-beginning 1))
		  (match-finish (+ (match-beginning 1) match-length))
		  )
	      (replace-match "\\2")
	      (link-create-link
	       match-start
	       match-finish
	       'edict-reference-define-face
	       'edict-new-search
	       (edict-replace-spaces
		(buffer-substring-no-properties match-start match-finish))
	       )
	      )
	    )
	(goto-char (point-max))
	)
      )
    )
  (beginning-of-buffer)
  )

(defun edict-colorit-match ()
  (interactive)
  (let ((regexp1 "\"[^\"\n]*\"") (regexp2 "[^ \n][^ \n]*"))
    (beginning-of-buffer)
    (while (< (point) (point-max))
      (if (search-forward-regexp regexp1 nil t)
	  (link-create-link
	   (match-beginning 0)
	   (match-end 0)
	   'edict-reference-m1-face
	   'edict-new-search
	   (edict-replace-spaces
	    (buffer-substring-no-properties
	     (+ (match-beginning 0) 1)
	     (- (match-end 0) 1)))
	   )
	(goto-char (point-max))
	)
      )
    (beginning-of-buffer)
    (while (< (point) (point-max))
      (if (search-forward-regexp regexp2 nil t)
	  (unless
	      (or
	       (equal 0 (match-beginning 0))
	       (get-text-property (match-beginning 0) 'link-data)
	       )
	    (link-create-link
	     (match-beginning 0)
	     (match-end 0)
	     'edict-reference-m2-face
	     'edict-new-search
	     (edict-replace-spaces
	      (buffer-substring-no-properties
	       (match-beginning 0)
	       (match-end 0)))
	     )
	    )
	(goto-char (point-max))
	)
      )
    )
  (beginning-of-buffer)
  )

(defcustom edict-mode-hook
  nil
  "Hook run in edict mode buffers.")

(defun edict-mode ()
  "This is a mode for dict client implementing
the protocol defined in RFC 2229.

The default key bindings:

  q         close the edict buffer
  h         display the help information

  s         make a new SEARCH, i.e. ask for a database, strategy and query
            and show definitions
  d         make a new DEFINE, i.e. ask for a database and query
            and show definitions
  m         make a new MATCH, i.e. ask for database, strategy and query
            and show matches

  mouse-2   visit a link (DEFINE using all dictionaries)
  C-mouse-2 visit a link (DEFINE using asked dictionaries)

  SPC       search the marked region (DEFINE) in all dictionaries
"

  (interactive)

  (kill-all-local-variables)
  (buffer-disable-undo)
  (use-local-map edict-mode-map)
  (setq major-mode 'edict-mode)
  (setq mode-name "EDict")

;  (toggle-read-only t)

  (add-hook 'kill-buffer-hook 'edict-close t t)
  (run-hooks 'edict-mode-hook)
  )

(defvar edict-window-configuration
  nil
  "The window configuration to be restored upon closing the buffer")

(defvar edict-selected-window
  nil
  "The currently selected window")

(defun edict ()
  "Create a new edict buffer and install edict-mode"
  (interactive)

  (let (
	(buffer (generate-new-buffer "*Edict buffer*"))
	(window-configuration (current-window-configuration))
	(selected-window (frame-selected-window))
	)
    (switch-to-buffer-other-window buffer)
    (edict-mode)

    (make-local-variable 'edict-window-configuration)
    (make-local-variable 'edict-selected-window)
    (setq edict-window-configuration window-configuration)
    (setq edict-selected-window selected-window)
    )
  )

;(unless edict-mode-map
(setq edict-mode-map (make-sparse-keymap))
(suppress-keymap edict-mode-map)

(define-key edict-mode-map "q"
  'edict-close)

(define-key edict-mode-map "h"
  'edict-help)

(define-key edict-mode-map [mouse-2]
  'edict-define-on-click)

(define-key edict-mode-map [C-down-mouse-2]
  'edict-define-with-db-on-click)

; SEARCH = MATCH + DEFINE
(define-key edict-mode-map "s"
  '(lambda ()
     (interactive)
     (edict-search
      (edict-select-database)
      (edict-select-strategy)
      (edict-read-query)
      'edict-search-base
      )
     )
  )

; MATCH
(define-key edict-mode-map "m"
  '(lambda ()
     (interactive)
     (edict-search
      (edict-select-database)
      (edict-select-strategy)
      (edict-read-query)
      'edict-match-base
      )
     )
  )

; DEFINE
(define-key edict-mode-map "d"
  '(lambda ()
     (interactive)
     (edict-search
      (edict-select-database)
      nil
      (edict-read-query)
      'edict-define-base
      )
     )
  )

; DEFINE for the selected region
(define-key edict-mode-map " "
  '(lambda ()
     (interactive)
     (edict-search
      "*"
      nil
      (thing-at-point 'word)
      'edict-define-base
      )
     )
  )

; DEFINE for the selected region
(define-key edict-mode-map [C-SPC]
  '(lambda ()
     (interactive)
     (edict-search
      (edict-select-database edict-last-database)
      nil
      (thing-at-point 'word)
      'edict-define-base
      )
     )
  )

;  (link-initialize-keymap edict-mode-map)

(defun edict-mode-p ()
  "Return non-nil if current buffer has edict-mode"
  (eq major-mode 'edict-mode))

(defun edict-ensure-buffer ()
  "If current buffer is not a edict buffer, create a new one."
  (unless (edict-mode-p)
    (edict)
    )
  )

(defun edict-close ()
  "Close the current edict buffer"
  (interactive)

  (if (eq major-mode 'edict-mode)
      (progn
	(setq major-mode nil)
	(let ((configuration edict-window-configuration)
	      (selected-window edict-selected-window))
	  (kill-buffer (current-buffer))
	  (if (window-live-p selected-window)
	      (progn
		(select-window selected-window)
		(set-window-configuration configuration)))
	  )
	)
    )
  )

(defun edict-search-base (database query strategy)
  "Edict search: MATCH + DEFINE"
  (interactive)

  (call-process
   edict-client-prog nil (current-buffer) nil
   "-P" "-" "-d" database "-s" strategy
   "-h" edict-server "-p" edict-port
   query
   )
  (edict-colorit-define)
  )

(defun edict-define-base (database query strategy)
  "Edict search: DEFINE"
  (interactive)

  (call-process
   edict-client-prog nil (current-buffer) nil
   "-P" "-" "-d" database
   "-h" edict-server "-p" edict-port
   query
   )
  (edict-colorit-define)
  )

(defun edict-match-base (database query strategy)
  "Edict search: MATCH"
  (interactive)

  (call-process
   edict-client-prog nil (current-buffer) nil
   "-P" "-" "-d" database "-s" strategy
   "-h" edict-server "-p" edict-port "-m"
   query
   )
  (edict-colorit-match)
  )

; search type may be "", 'edict-define or 'edict-match
(defun edict-search (database strategy query search-fun)
  "Creates new *Edict* buffer and run search-fun"
  (interactive)

  (let ((coding-system nil))
    (if (and (functionp 'coding-system-list)
	     (member 'utf-8 (coding-system-list)))
 	(setq coding-system 'utf-8))
    (let (
	  (selected-window (frame-selected-window))
	  (coding-system-for-read coding-system)
	  (coding-system-for-write coding-system)
	  )
      (edict)
      (funcall search-fun database query strategy)
      (beginning-of-buffer)
      )
    )
  )
