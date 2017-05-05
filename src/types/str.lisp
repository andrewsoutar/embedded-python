#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/types/str
    (:documentation "Python strings")
  (:use :cl)
  (:use :cffi :named-readtables)
  (:use :com.andrewsoutar.bootstrap :com.andrewsoutar.brace-lambda)
  #+sbcl (:import-from :sb-alien #:c-string-to-string #:string-to-c-string)
  #+sbcl (:import-from :sb-sys #:vector-sap #:with-pinned-objects)
  (:use :com.andrewsoutar.embedded-python/grovel)
  (:use
   :com.andrewsoutar.embedded-python/src/class
   :com.andrewsoutar.embedded-python/src/ffi-types
   :com.andrewsoutar.embedded-python/src/init
   :com.andrewsoutar.embedded-python/src/types
   :com.andrewsoutar.embedded-python/src/vm-call)
  (:export #:python-str))
(in-package :com.andrewsoutar.embedded-python/src/types/str)

(in-readtable brace-lambda)

(defcfun-py (decode-string "PyUnicode_DecodeUTF8") py-object
  (s (:pointer :char))
  (size py-ssize)
  (errors :string))

(defun non-null-or-die (ptr)
  (if (null-pointer-p ptr)
      (maybe-handle-exception)
      ptr))
(defcfun-py (encode-string "PyUnicode_AsUTF8")
    (:wrapper (:pointer :char) :from-c non-null-or-die)
  (python-string py-object))

(defbootstrap python-str (:after start-python)
  {()
   (define-python-class-from-c python-str "PyUnicode_Type")

   (defmethod convert-from-python ((object python-str))
     (c-string-to-string (encode-string object)
                         :utf8 'character))

   (defmethod convert-to-python ((object string))
     (let ((vector (string-to-c-string object :utf8)))
       (with-pinned-objects (vector)
         (decode-string
          (vector-sap vector)
          (length object)
          (null-pointer)))))})
