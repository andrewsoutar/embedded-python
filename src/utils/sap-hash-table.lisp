#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/utils/sap-hash-table
    (:documentation "A hash table which can use system-area-pointers as keys")
  (:use :cl)
  (:import-from :sb-ext #:define-hash-table-test #:sap= #:sap-int)
  (:export #:sap-equal))
(in-package :com.andrewsoutar.embedded-python/src/utils/sap-hash-table)

(setf (fdefinition 'sap-equal) (fdefinition 'sap=))

(defun hash-sap (sap)
  (sxhash (sap-int sap)))

(define-hash-table-test sap-equal hash-sap)
