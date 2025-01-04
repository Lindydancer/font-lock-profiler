;;; font-lock-profiler-test.el --- Tests for font-lock-profiler.  -*- lexical-binding: t; -*-

;; Copyright (C) 2016 Anders Lindgren

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

;; `faceup' is a markup language than can represent syntax highlighted
;; text using a semi-human readable text format. The package also
;; contains support for testing font-lock packages using ERT (the
;; Emacs Regression Testing package).

(require 'faceup)

;; `font-lock-regression-suite' contains a large number of source
;; files written in a variety of programming languages.

(require 'font-lock-regression-suite)


(defun font-lock-profiler-test-with-and-without-profiling
    (&optional buffer verbose)
  "True if instrumenting font-lock keywords in BUFFER yield correct result.

If VERBOSE is non-nil, or when the function is called
interactively, print the result.

This function can be used as an ERT predicate."
  (interactive '(nil t))
  (unless buffer
    (setq buffer (current-buffer)))
  (let ((result-without
         (with-current-buffer buffer
           (font-lock-fontify-region (point-min) (point-max))
           (faceup-markup-buffer)))
        (result-with
         (with-current-buffer buffer
           (let ((font-lock-keywords
                  (font-lock-profiler-instrument-keyword-list
                   font-lock-keywords)))
             (font-lock-fontify-region (point-min) (point-max))
             (faceup-markup-buffer)))))
    (let ((res (faceup-test-equal result-without result-with)))
      (if verbose
          (message (if res
                       "Results are equal"
                     "Results are NOT equal")))
      res)))

(faceup-defexplainer font-lock-profiler-test-with-and-without-profiling)


(defun font-lock-profiler-test-add-ert-cases ()
  "Generate a number of ERT testcases.

The test cases checks that the end result is the same with normal
and profiled font-lock keywords. The source files are provided by
`font-lock-regression-suite'."
  (interactive)
  (font-lock-regression-suite-each-src-ref-file
   (lambda (name
            src-file
            ref-file
            mode)
     (eval `(ert-deftest ,(intern (concat "font-lock-profiler--" name)) ()
              (with-temp-buffer
                (insert-file-contents ,src-file)
                ;; Clear some hook. Doesn't catch global minor
                ;; modes, though.
                (let ((prog-mode-hook nil)
                      (,(intern (concat (symbol-name mode) "-hook")) nil))
                  (,mode))
                (font-lock-profiler-test-with-and-without-profiling)))))))

;;; font-lock-profiler-test.el ends here
