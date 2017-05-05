#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/types/float
    (:documentation "Python floats")
  (:use :cl)
  (:use :named-readtables)
  (:use :com.andrewsoutar.bootstrap :com.andrewsoutar.brace-lambda)
  (:use
   :com.andrewsoutar.embedded-python/src/class
   :com.andrewsoutar.embedded-python/src/ffi-types
   :com.andrewsoutar.embedded-python/src/init
   :com.andrewsoutar.embedded-python/src/types
   :com.andrewsoutar.embedded-python/src/vm-call)
  (:export #:python-float))
(in-package :com.andrewsoutar.embedded-python/src/types/float)

(in-readtable brace-lambda)

(defcfun-py (%make-python-float "PyFloat_FromDouble") py-object
  (value :double))

(defcfun-py (%convert-python-float "PyFloat_AsDouble") :double
  (float py-object))

(defbootstrap python-float (:after start-python)
  {()
   (define-python-class-from-c python-float "PyFloat_Type")

   (defmethod convert-to-python ((object float))
     (%make-python-float object))

   (defmethod convert-from-python ((object python-float))
     (let ((result (%convert-python-float object)))
       (when (= result -1.0)
         (maybe-handle-exception))
       result))})
