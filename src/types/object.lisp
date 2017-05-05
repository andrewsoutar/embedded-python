#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/types/object
    (:documentation "Generic things for objects")
  (:use :cl)
  (:use :named-readtables)
  (:use
   :com.andrewsoutar.embedded-python/src/types
   :com.andrewsoutar.embedded-python/src/syntax))
(in-package :com.andrewsoutar.embedded-python/src/types/object)

(in-readtable python-syntax)

(defmethod print-object ((object python-object-wrapper) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (write-string (with-builtins (str) [str (object)]) stream)))
