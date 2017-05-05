#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/refcount
    (:documentation "Reference counting")
  (:use :cl)
  (:use :cffi)
  #+sbcl (:import-from :sb-sys #:system-area-pointer)
  (:use :com.andrewsoutar.embedded-python/grovel)
  (:use :com.andrewsoutar.embedded-python/src/vm-call)
  (:export #:incref #:decref))
(in-package :com.andrewsoutar.embedded-python/src/refcount)

(defcfun-py (%incref "Py_IncRef") :void (o (:pointer (:struct %py-object))))
(defgeneric incref (object)
  (:method :around (object)
    (call-next-method)
    object)
  (:method ((object system-area-pointer))
    (%incref object)))

(defcfun-py (%decref "Py_DecRef") :void (o (:pointer (:struct %py-object))))
(defgeneric decref (object)
  (:method :around (object)
    (call-next-method)
    object)
  (:method ((object system-area-pointer))
    (%decref object)))
