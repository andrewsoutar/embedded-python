#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/types/none
    (:documentation "Python's `None' type")
  (:use :cl)
  (:use :named-readtables)
  (:use :com.andrewsoutar.bootstrap :com.andrewsoutar.brace-lambda)
  (:use :com.andrewsoutar.embedded-python/grovel)
  (:use
   :com.andrewsoutar.embedded-python/src/class
   :com.andrewsoutar.embedded-python/src/ffi-types
   :com.andrewsoutar.embedded-python/src/init
   :com.andrewsoutar.embedded-python/src/refcount
   :com.andrewsoutar.embedded-python/src/syntax
   :com.andrewsoutar.embedded-python/src/types)
  (:export #:python-none #:*python-none* #:python-none-type))
(in-package :com.andrewsoutar.embedded-python/src/types/none)

(in-readtable python-and-braces)

(defvar *python-none*)

(defbootstrap python-none (:after (start-python python-syntax))
  {()
   (with-builtins ((none "None"))
     (setf *python-none* none))

   (define-python-class python-none-type (class-of *python-none*))

   (values (defmethod convert-from-python ((object python-none-type)) nil)
           (defmethod convert-from-python ((object null)) nil))}
  {(&rest methods)
   (makunbound '*python-none*)
   (mapcar {remove-method #'convert-from-python %*} methods)
   (values)})
