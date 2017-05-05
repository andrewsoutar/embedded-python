#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/utils/symbols
    (:documentation "Helpers for creating symbols and such")
  (:use :cl)
  (:use :alexandria)
  (:export #:symbolize))
(in-package :com.andrewsoutar.embedded-python/src/utils/symbols)

(defun symbolize (package &rest parts)
  (apply 'format-symbol package "~@{~A~^-~}" parts))
