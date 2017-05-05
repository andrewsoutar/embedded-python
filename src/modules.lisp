#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/modules
    (:documentation "Importing and using modules")
  (:use :cl)
  (:use :alexandria :named-readtables)
  (:use :com.andrewsoutar.brace-lambda)
  (:use
   :com.andrewsoutar.embedded-python/src/ffi-types
   :com.andrewsoutar.embedded-python/src/vm-call)
  (:export #:python-import #:with-imports))
(in-package :com.andrewsoutar.embedded-python/src/modules)

(in-readtable brace-lambda)

(defcfun-py (python-import "PyImport_Import") py-object (name py-object))

(defmacro with-imports ((&rest imports) &body forms)
  `(let ,(mapcar (compose {((name &optional (import-string
                                             (string-downcase name))))
                           `(,name (python-import ,import-string))}
                          'ensure-list)
                 imports)
     ,@forms))
