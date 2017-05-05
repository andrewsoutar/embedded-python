#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/types/exception
    (:documentation "Exceptions")
  (:use :cl)
  (:use :cffi :named-readtables)
  (:use :com.andrewsoutar.bootstrap)
  (:use
   :com.andrewsoutar.embedded-python/src/class
   :com.andrewsoutar.embedded-python/src/ffi-types
   :com.andrewsoutar.embedded-python/src/init
   :com.andrewsoutar.embedded-python/src/syntax
   :com.andrewsoutar.embedded-python/src/types/none
   :com.andrewsoutar.embedded-python/src/vm-call)
  (:export #:python-exception #:python-base-exception))
(in-package :com.andrewsoutar.embedded-python/src/types/exception)

(in-readtable python-and-braces)

(defbootstrap python-base-exception (:after start-python)
  {()
   (define-python-class-from-c python-base-exception
       ("PyExc_BaseException" :deref t))})

(defun report-exception (condition stream)
  (with-slots (type value traceback) condition
    (with-imports ((tb "traceback"))
      (format stream "Python exception:~%~{~A~}"
              (coerce
               [tb.format_exception (type, value, (or traceback *python-none*))]
               'list)))))

(define-condition python-exception (error)
  ((type :initarg :type :reader exception-type)
   (value :initarg :value :reader exception-value)
   (traceback :initarg :traceback :reader exception-traceback))
  (:report report-exception))

(defcfun-py (fetch-exception "PyErr_Fetch") :void
  (type (:pointer py-object))
  (value (:pointer py-object))
  (traceback (:pointer py-object)))
(defcfun-py (normalize-exception "PyErr_NormalizeException") :void
  (type (:pointer py-object))
  (value (:pointer py-object))
  (traceback (:pointer py-object)))

(defun maybe-handle-exception ()
  (with-foreign-objects ((type 'py-object) (value 'py-object)
                         (traceback 'py-object))
    (fetch-exception type value traceback)
    (unless (null-pointer-p (mem-ref type :pointer))
      (normalize-exception type value traceback)
      (error 'python-exception
             :type (mem-ref type 'py-object)
             :value (mem-ref value 'py-object)
             :traceback (mem-ref traceback 'py-object)))))
