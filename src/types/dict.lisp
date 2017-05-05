#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/types/dict
    (:documentation "Python dictionaries")
  (:use :cl)
  (:use :alexandria :named-readtables)
  (:use :com.andrewsoutar.bootstrap :com.andrewsoutar.brace-lambda)
  (:use
   :com.andrewsoutar.embedded-python/src/class
   :com.andrewsoutar.embedded-python/src/ffi-types
   :com.andrewsoutar.embedded-python/src/init
   :com.andrewsoutar.embedded-python/src/syntax
   :com.andrewsoutar.embedded-python/src/types
   :com.andrewsoutar.embedded-python/src/vm-call)
  (:export #:python-dict #:python-dict-to-plist))
(in-package :com.andrewsoutar.embedded-python/src/types/dict)

(in-readtable python-and-braces)

(defcfun-py (dict-items "PyDict_Items") py-object
  (dict py-object))
(defun python-dict-to-plist (dict)
  (mapcan {`(,(make-keyword (string-upcase (elt %1 0))) ,(elt %1 1))}
          (coerce (dict-items dict) 'list)))

(defbootstrap python-dict (:after start-python)
  {()
   (define-python-class-from-c python-dict "PyDict_Type")

   (defmethod convert-to-python ((object hash-table))
     (let ((dict (make-instance 'python-dict)))
       (maphash {setf [dict [(string-downcase %1)]] %2} object)
       dict))})
