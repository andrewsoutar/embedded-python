#+named-readtables
(named-readtables:in-readtable :standard)

#-sbcl (error "You need SBCL to use SBCL-LIST")

(uiop:define-package :com.andrewsoutar.embedded-python/src/types/sbcl-list
    (:documentation #. (format nil "A subtype of `python-sequence' with ~
optimizations for Python lists"))
  (:use :cl)
  (:use :alexandria :named-readtables)
  (:use :com.andrewsoutar.bootstrap :com.andrewsoutar.brace-lambda)
  (:use :com.andrewsoutar.embedded-python/grovel)
  (:use
   :com.andrewsoutar.embedded-python/src/class
   :com.andrewsoutar.embedded-python/src/ffi-types
   :com.andrewsoutar.embedded-python/src/init
   :com.andrewsoutar.embedded-python/src/types
   :com.andrewsoutar.embedded-python/src/types/sbcl-sequence
   :com.andrewsoutar.embedded-python/src/vm-call)
  (:export #:python-list))
(in-package :com.andrewsoutar.embedded-python/src/types/sbcl-list)

(in-readtable brace-lambda)

(defcfun-py (set-elt "PyList_SetItem") zero-on-success
  (list py-object)
  (index py-ssize)
  (new-value (py-object :stolen t)))

(defcfun-py (list-reverse "PyList_Reverse") zero-on-success
  (list py-object))

(defbootstrap python-list (:after start-python)
  {()
   (define-python-class-from-c python-list "PyList_Type"
     :direct-superclasses 'python-sequence)

   (defmethod construct-python-instance :around ((object python-list)
                                                 &key elements)
     (call-next-method object :python-args `(,(coerce elements 'list))))

   (defmethod populate-sequence ((sequence python-list) &rest elements)
     (declare (ignore elements)))

   (defmethod sequence:nreverse ((list python-list))
     (list-reverse list)
     list)

   (defmethod convert-to-python ((object vector))
     (concatenate 'python-list object))})
