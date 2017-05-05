#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/types/function
    (:documentation "Callbacks from Python into Common Lisp")
  (:use :cl)
  (:use :bordeaux-threads :cffi)
  (:use :com.andrewsoutar.bootstrap)
  #+sbcl (:import-from :sb-concurrency #:make-queue #:enqueue #:dequeue)
  #+sbcl (:import-from :sb-ext #:with-locked-hash-table)
  (:use :com.andrewsoutar.embedded-python/grovel)
  (:use
   :com.andrewsoutar.embedded-python/src/ffi-types
   :com.andrewsoutar.embedded-python/src/static-callback
   :com.andrewsoutar.embedded-python/src/types
   :com.andrewsoutar.embedded-python/src/types/dict
   :com.andrewsoutar.embedded-python/src/types/weakref
   :com.andrewsoutar.embedded-python/src/vm-call)
  (:export #:python-function))
(in-package :com.andrewsoutar.embedded-python/src/types/function)

(defvar *foreign-callback-table*
  (make-array 32 :element-type 'function :fill-pointer 0 :adjustable t))
(defvar *foreign-callback-table-lock* (make-lock))
(defvar *foreign-callback-table-free-list* (make-queue))
(defvar *foreign-callback-translation-cache*
  (make-hash-table :weakness :key-and-value :synchronized t))

(define-static-python-callback call-into-lisp (index args kwargs)
  (destructuring-bind (index args kwargs)
      (mapcar 'convert-from-python `(,index ,args ,kwargs))
    (apply (aref *foreign-callback-table* index)
           (nconc args (when kwargs (python-dict-to-plist kwargs))))))

(define-static-python-callback cleanup-callback (index args kwargs)
  (declare (ignore args kwargs))
  (with-lock-held (*foreign-callback-table-lock*)
    (setf (aref *foreign-callback-table* index) nil))
  (enqueue index *foreign-callback-table-free-list*))

(defcfun-py (function-new "PyCFunction_New") py-object
  (method (:pointer (:struct py-method-def)))
  (self py-object))

(defmethod convert-to-python ((object function))
  (multiple-value-bind (method foundp)
      #1= (gethash object *foreign-callback-translation-cache*)
    (when foundp
      (return-from convert-to-python method))
    (let* ((index
             (multiple-value-bind (free have-free)
                 (dequeue *foreign-callback-table-free-list*)
               (if have-free
                   (with-lock-held (*foreign-callback-table-lock*)
                     (setf (aref *foreign-callback-table* free) object)
                     free)
                   (with-lock-held (*foreign-callback-table-lock*)
                     (vector-push-extend object *foreign-callback-table*)))))
           (python-function (function-new call-into-lisp index)))
      (make-instance 'python-weakref
                     :object python-function
                     :callback (function-new cleanup-callback index))
      (setf #1# python-function))))

(defbootstrap python-function (:after (call-into-lisp cleanup-callback)))
