#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/ffi-types
    (:documentation "Type setup for the foreign function interface")
  (:use :cl)
  (:use :cffi :uiop)
  #+sbcl (:import-from :sb-sys #:system-area-pointer #:with-pinned-objects)
  (:use :com.andrewsoutar.embedded-python/grovel)
  (:use
   :com.andrewsoutar.embedded-python/src/macros
   :com.andrewsoutar.embedded-python/src/refcount
   :com.andrewsoutar.embedded-python/src/types)
  (:export #:zero-on-success #:wrap-pointer
           #:py-object #:maybe-handle-exception #:with-unwrapped-object))
(in-package :com.andrewsoutar.embedded-python/src/ffi-types)

(defun zero-on-success-helper (int)
  (unless (zerop int)
    (maybe-handle-exception))
  int)
(defctype zero-on-success (:wrapper :int :from-c zero-on-success-helper))


(define-foreign-type py-object-type ()
  ((stolen :reader stolen :initarg :stolen :initform nil)
   (borrowed :reader borrowed :initarg :borrowed :initform nil)
   (dont-wrap :reader dont-wrap :initarg :dont-wrap :initform nil))
  (:actual-type :pointer (:struct %py-object))
  (:simple-parser py-object))

(defun safely-unwrap (object)
  (with-pinned-objects (object)
    (incref (unwrap object))))

(defgeneric wrap-pointer (pointer)
  (:method ((pointer null)) nil))

(defmethod translate-to-foreign :around (object (type py-object-type))
  (let ((object (call-next-method)))
    (if (stolen type)
        (incref object)
        object)))

(defmethod translate-to-foreign ((object system-area-pointer)
                                 (type py-object-type))
  (incref object))

(defmethod translate-to-foreign ((object python-object-wrapper)
                                 (type py-object-type))
  (safely-unwrap object))

(defmethod translate-to-foreign (object (type py-object-type))
  (translate-to-foreign (convert-to-python object) type))

(defmethod translate-from-foreign (python-object (type py-object-type))
  (when (null-pointer-p python-object)
    (maybe-handle-exception))
  (when (borrowed type)
    (incref python-object))
  (if (dont-wrap type)
      python-object
      (wrap-pointer python-object)))

(defmethod free-translated-object (python-object (type py-object-type) param)
  (decref python-object))

(defmethod expand-from-foreign (value (type py-object-type))
  `(nest
    ,@(unless (dont-wrap type)
       '((wrap-pointer)))
    ,@(when (borrowed type)
       '((incref)))
    (let ((value ,value))
      (when (null-pointer-p value)
        (maybe-handle-exception))
      value)))

(defun foreign-expansion-helper (object var body stolen)
  `(threadsafe-unwind-protect
       (,var (nest ,@(when stolen '((incref)))
                   (let ((object ,object))
                     (if (typep object 'system-area-pointer)
                         (incref object)
                         (safely-unwrap
                          (if (typep object 'python-object-wrapper)
                              object
                              (with-interrupts (convert-to-python object))))))))
       (progn ,@body)
     (decref ,var)))

(defmethod expand-to-foreign-dyn (object var body (type py-object-type))
  (foreign-expansion-helper object var body (stolen type)))

(defmacro with-unwrapped-object ((var object) &body body)
  (foreign-expansion-helper object var body nil))
