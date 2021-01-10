#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/types/list
  (:documentation "Convert Python lists to vectors, and back")
  (:use :cl)
  (:use :named-readtables)
  (:use :com.andrewsoutar.bootstrap :com.andrewsoutar.brace-lambda)
  (:use :com.andrewsoutar.embedded-python/grovel)
  (:use
   :com.andrewsoutar.embedded-python/src/ffi-types
   :com.andrewsoutar.embedded-python/src/vm-call))
(in-package :com.andrewsoutar.embedded-python/src/types/list)

(in-readtable brace-lambda)

(defcfun-py (make-python-list "PyList_New") py-object
  (len py-ssize))

(defcfun-py (python-list-length "PyList_Size") py-ssize
  (list py-object))

(defcfun-py (python-list-elt "PyList_GetItem") (py-object :borrowed t)
  (list py-object)
  (index py-ssize))

(defcfun-py (python-list-set-elt "PyList_SetItem") zero-on-success
  (list py-object)
  (index py-ssize)
  (new-value (py-object :stolen t)))

(defbootstrap python-list (:after start-python)
  {()
   (define-python-class-from-c python-list "PyList_Type")

   (defmethod convert-to-python ((object vector))
     (let ((py-list (make-python-list (length object))))
       (loop for i from 0
	     for el across object
	     do (python-list-set-elt py-list i el))
       py-list))

   (defmethod convert-from-python ((object python-list))
     (let ((vector (make-array (python-list-length object))))
       (loop for i from 0 below (length vector)
	     do (setf (svref vector i) (python-list-elt object i)))
       vector))})
