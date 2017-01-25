;;; dummy-delay-mode.el --- Dummy mode with delays in font-lock keywords  -*- lexical-binding: t; -*-

;; Copyright (C) 2017  Anders Lindgren

;; Author: Anders Lindgren

;; This program is free software; you can redistribute it and/or modify
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

;; Dummy major mode with delays in various parts of font-lock
;; keywords.
;;
;; This mode is intended to be used to test Font Lock Profiler. It is
;; designed to run each basic font-lock keyword expression a few
;; times, and do a 0.5 seconds delay. The total run time is about 5
;; seconds, for small but non-empty buffers.
;;
;; Unfortuantely, time measurements are not exact, so it's non-trivial
;; to make an automatic test for this.

;; Example:
;;
;; When running `font-lock-profiler-buffer' on a (non-empty) buffer,
;; the following result is presented (long lines truncated):
;;
;;     Id     Count          Time  Keyword
;;        0             0             0%  (dummy-delay-mode-...
;;        1             1            30%  (dummy-delay-mode-...
;;        2             1            70%  (dummy-delay-mode-...
;;
;; Pressing `x' in the report buffer will reveal more details:
;;
;;     Id          Count       Time  Keyword
;;           0                  0               0%  dummy-delay-mode-...
;;        0            0         0%   (0 (quote font-lock-warning-face))
;;     --------------------
;;           1                  1              20%  dummy-delay-mode-...
;;         0           1        10%   (0 (progn (sleep-for 0.5) ...
;;     --------------------
;;           2                  1              20%  dummy-delay-mode-matcher-match-every-other
;;         0                     0%   dummy-delay-mode-...
;;           Pre                 0%     nil
;;           Post                0%     nil
;;         1                    20%   dummy-delay-mode-...
;;           Pre                10%     (progn (sleep-for 0.5) nil)
;;           Post               10%     (progn (sleep-for 0.5) nil)
;;           0         1        10%     (0 (progn (sleep-for 0.5) ...
;;         2                     0%   dummy-delay-mode-matcher-...
;;           Pre                 0%     nil
;;           Post                0%     nil
;;     --------------------

;;; Code:

(defvar dummy-delay-mode-match-next t)

(defun dummy-delay-mode-matcher-match-next-should-match (limit)
  "Make next call to `dummy-delay-mode-matcher-match-every-other' succeed."
  (setq dummy-delay-mode-match-next t)
  nil)

(defun dummy-delay-mode-matcher-match-next-should-fail (limit)
  "Make next call to `dummy-delay-mode-matcher-match-every-other' fail."
  (setq dummy-delay-mode-match-next nil)
  nil)

(defun dummy-delay-mode-matcher-match-every-other (limit)
  "Font-lock matcher that match and fail alternatively.

When called, it will delay for 0.5 seconds.

When `dummy-delay-mode-matcher-match-next-should-match' and
`dummy-delay-mode-matcher-match-next-should-fail' are called, the
next call to this function will match and fail, respectively."
  (sleep-for 0.5)
  (looking-at "^.*$")                   ; To get a match-data.
  (prog1
      dummy-delay-mode-match-next
    (setq dummy-delay-mode-match-next
          (not dummy-delay-mode-match-next))))

(defvar dummy-delay-mode-keywords
  '((dummy-delay-mode-matcher-match-next-should-match
     (0 'font-lock-warning-face))
    ;; This will match once.
    (dummy-delay-mode-matcher-match-every-other
     (0 (progn
          (sleep-for 0.5)
          'font-lock-warning-face)))
    ;; This will match once.
    (dummy-delay-mode-matcher-match-every-other
     (dummy-delay-mode-matcher-match-next-should-match
      nil
      nil)
     ;; This will match once.
     (dummy-delay-mode-matcher-match-every-other
      ;; Pre-match form.
      (progn
        (sleep-for 0.5)
        nil)
      ;; Post-match form.
      (progn
        (sleep-for 0.5)
        nil)
      (0 (progn
           (sleep-for 0.5)
           'font-lock-warning-face)))
     (dummy-delay-mode-matcher-match-next-should-fail
      nil
      nil)))
  "Font-lock keywords for DummyDelay mode.

The keywords contains delays, making them suitable to be used to
test Font-Lock Profiler.")


(define-derived-mode dummy-delay-mode nil "DummyDelay"
  "Dummy mode with delays on the font-lock keywords."
  (make-local-variable 'dummy-delay-mode-match-next)
  (setq font-lock-defaults '(dummy-delay-mode-keywords nil)))


(provide 'dummy-delay-mode)

;;; dummy-delay-mode.el ends here
