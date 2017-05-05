#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/types/tuple
    (:documentation "Python's tuple class")
  (:use :cl)
  (:use :named-readtables)
  (:use :com.andrewsoutar.bootstrap :com.andrewsoutar.brace-lambda)
  #+sbcl (:import-from :sb-sys #:with-pinned-objects)
  (:use :com.andrewsoutar.embedded-python/grovel)
  (:use
   :com.andrewsoutar.embedded-python/src/class
   :com.andrewsoutar.embedded-python/src/ffi-types
   :com.andrewsoutar.embedded-python/src/init
   :com.andrewsoutar.embedded-python/src/types
   :com.andrewsoutar.embedded-python/src/vm-call)
  (:export #:python-tuple))
(in-package :com.andrewsoutar.embedded-python/src/types/tuple)

(in-readtable brace-lambda)

(defcfun-py (tuple-length "PyTuple_Size") py-ssize (tuple py-object))

(defcfun-py (tuple-unwrapped-item "PyTuple_GetItem")
            (py-object :borrowed t :dont-wrap t)
  (tuple py-object) (index py-ssize))

(defcfun-py (tuple-item "PyTuple_GetItem") (py-object :borrowed t)
  (tuple py-object)
  (index py-ssize))

(defcfun-py (tuple-new "PyTuple_New") py-object (length py-ssize))

(defcfun-py (%tuple-set-item "PyTuple_SetItem") zero-on-success
  (tuple :pointer)
  (index py-ssize)
  (object (py-object :stolen t)))

(defbootstrap python-tuple (:after start-python)
  {()
   (define-python-class-from-c python-tuple "PyTuple_Type")

   (defmethod convert-from-python ((object python-tuple))
     (loop for i from 0 below (tuple-length object)
           collect (convert-from-python (tuple-item object i))))

   (defun (setf tuple-item) (new-value tuple index)
     (with-pinned-objects (tuple)
       (%tuple-set-item (unwrap tuple) index new-value)))

   (defmethod convert-to-python ((object list))
     (let ((com.andrewsoutar.embedded-python/src/types::*recursive* t))
       (loop with tuple = (tuple-new (length object))
             for i from 0
             for element in object
             do (setf (tuple-item tuple i) element)
             finally (return tuple))))})
