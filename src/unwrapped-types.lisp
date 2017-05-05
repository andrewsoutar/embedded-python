#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/unwrapped-types
    (:documentation "Getting unwrapped values from types, for use in wrapping")
  (:use :cl)
  (:use :com.andrewsoutar.embedded-python/grovel)
  (:use
   :com.andrewsoutar.embedded-python/src/ffi-types
   :com.andrewsoutar.embedded-python/src/vm-call)
  (:export #:unwrapped-python-type #:get-unwrapped-attr
           #:tuple-length #:tuple-unwrapped-item))
(in-package :com.andrewsoutar.embedded-python/src/unwrapped-types)

(defcfun-py (unwrapped-python-type "PyObject_Type") (py-object :dont-wrap t)
  (object py-object))

(defcfun-py (get-unwrapped-attr "PyObject_GetAttrString")
            (py-object :dont-wrap t)
  (object py-object)
  (attr :string))

(defcfun-py (tuple-length "PyTuple_Size") py-ssize (tuple py-object))

(defcfun-py (tuple-unwrapped-item "PyTuple_GetItem")
            (py-object :borrowed t :dont-wrap t)
  (tuple py-object) (index py-ssize))

