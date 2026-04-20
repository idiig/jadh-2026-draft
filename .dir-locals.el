;;; .dir-locals.el — local Emacs settings for docs/

((org-mode
  . ((eval . (progn
               (defun my-filter-nobreaks (text backend info)
                 "Remove newlines between CJK characters in all export formats."
                 (replace-regexp-in-string 
                  "\\([\u3000-\u9fff\uff00-\uffef]\\)\n\\([\u3000-\u9fff\uff00-\uffef]\\)"
                  "\\1\\2"
                  text))

               (with-eval-after-load 'ox
                 (unless (memq 'my-filter-nobreaks org-export-filter-plain-text-functions)
                   (add-to-list 'org-export-filter-plain-text-functions
                                'my-filter-nobreaks)))

               (defun my-html-image-width (text backend info)
                 "Set all images to width 100% in HTML export."
                 (when (org-export-derived-backend-p backend 'html)
                   (replace-regexp-in-string 
                    "<img src=\"\\([^\"]+\\)\"" 
                    "<img style=\"width:100%\" src=\"\\1\"" 
                    text)))

               (unless (memq 'my-html-image-width org-export-filter-final-output-functions)
                 (add-to-list 'org-export-filter-final-output-functions
                              'my-html-image-width))

               (defun my/org-typst-latex-fix-times (latex-fragment)
                 "Fix \\times in LaTeX fragments."
                 (let ((result (org-typst-from-latex-with-naive latex-fragment)))
                   (when result
                     (replace-regexp-in-string "\\\\times" "times" result))))

               (setq-local org-typst-from-latex-fragment 'my/org-typst-latex-fix-times)

	       (defun my-typst-fix-label (text backend info)
		 "Fix label syntax in Typst export."
		 (when (org-export-derived-backend-p backend 'typst)
		   (replace-regexp-in-string 
		    "#label(\"\\([^\"]+\\)\")\\[\\([0-9]+\\)\\]"
		    "[\\2] #label(\"\\1\")"
		    text)))

	       (with-eval-after-load 'ox-typst
		 (unless (memq 'my-typst-fix-label org-export-filter-final-output-functions)
		   (add-to-list 'org-export-filter-final-output-functions
				'my-typst-fix-label)))

	       (defun my-typst-image-width (text backend info)
		 "Set image width to 0.5 textwidth in Typst export."
		 (when (org-export-derived-backend-p backend 'typst)
		   (replace-regexp-in-string 
		    "#figure(\\[#image(\\([^)]+\\))\\])"
		    "#figure([#image(\\1, width: 100%)])"
		    text)))

	       (with-eval-after-load 'ox-typst
		 (unless (memq 'my-typst-image-width org-export-filter-final-output-functions)
		   (add-to-list 'org-export-filter-final-output-functions
				'my-typst-image-width)))))
     
     (defun kugire-short-manuscript ()
       "Write a short version of the manuscript to manuscript-short.org.
Keeps the #+title, all first-level headings, and the TL;DR
#+begin_comment block that opens each section.  The original
buffer is not modified.  Output file is written next to the
source file and opened in a new window."
       (interactive)
       (let* ((src-buf (current-buffer))
              (out-file (expand-file-name
			 "manuscript-short.org"
			 (file-name-directory (buffer-file-name src-buf))))
              title
              sections)
	 ;; ── collect title ────────────────────────────────────────
	 (with-current-buffer src-buf
	   (save-excursion
             (goto-char (point-min))
             (when (re-search-forward "^#\\+title:[ \t]*\\(.*\\)$" nil t)
               (setq title (match-string-no-properties 1))))
	   ;; ── collect headings + TL;DR comment-blocks ─────────────
	   ;; #+begin_comment...#+end_comment is parsed as 'comment-block
	   ;; (not 'special-block); its text is in :value.
	   (org-element-map (org-element-parse-buffer) 'headline
             (lambda (hl)
               (when (= (org-element-property :level hl) 1)
		 (let ((heading (org-element-property :raw-value hl))
                       (tldr nil))
		   (org-element-map (org-element-contents hl) 'comment-block
                     (lambda (blk)
                       (setq tldr
                             (replace-regexp-in-string
                              "^TL;DR:[ \t]*" ""
                              (string-trim
                               (org-element-property :value blk)))))
                     nil t) ; first match only
		   (push (cons heading tldr) sections))))))
	 ;; ── write output file ────────────────────────────────────
	 (with-temp-file out-file
	   (org-mode)
	   (when title
             (insert (format "#+title: %s\n\n" title)))
	   (dolist (sec (nreverse sections))
             (insert (format "* %s\n\n" (car sec)))
             (when (cdr sec)
               (insert (cdr sec))
               (insert "\n"))
             (insert "\n")))
	 (find-file-other-window out-file)
	 (goto-char (point-min))
	 (message "Short manuscript written to %s" out-file)))
     
     (org-confirm-babel-evaluate . nil)
     (org-image-actual-width . nil))))
