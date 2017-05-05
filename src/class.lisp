#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/class
    (:documentation "Class introspection and CLOS bindings")
  (:use :cl)
  (:use :alexandria :bordeaux-threads :cffi :named-readtables)
  (:use :com.andrewsoutar.brace-lambda)
  #+sbcl (:import-from :sb-ext #:with-locked-hash-table)
  #+sbcl (:import-from :sb-sys #:system-area-pointer)
  (:use
   :com.andrewsoutar.embedded-python/src/ffi-types
   :com.andrewsoutar.embedded-python/src/macros
   :com.andrewsoutar.embedded-python/src/operators
   :com.andrewsoutar.embedded-python/src/refcount
   :com.andrewsoutar.embedded-python/src/types
   :com.andrewsoutar.embedded-python/src/unwrapped-types
   :com.andrewsoutar.embedded-python/src/utils/sap-hash-table)
  (:export #:define-python-class #:define-python-class-from-c))
(in-package :com.andrewsoutar.embedded-python/src/class)

(in-readtable brace-lambda)

(defun get-bases (type)
  (threadsafe-unwind-protect
      (tuple (get-unwrapped-attr type "__bases__"))
      (loop for i from 0 below (tuple-length tuple)
            collect (tuple-unwrapped-item tuple i))
    (decref tuple)))


(defparameter *class-table-weak* nil)
(defvar *class-table*
  (make-hash-table :test 'sap-equal
                   :weakness (when *class-table-weak* :value)
                   :synchronized t))

(defvar *wrapper-cache*
  (make-hash-table :test 'sap-equal :weakness :value :synchronized t))

;;; This is kind of hairy. We want to avoid deadlocking (one thread is holding
;;; the GIL to translate an object, trying to create a class, and waiting for
;;; the hash table lock; another is inside the hash table lock, waiting for the
;;; GIL to do its introspection. To get around that, we separate the class
;;; creation into two steps: the initial creation of a bare class without any
;;; type information (created inside the hashtable lock), and the initialization
;;; of said class with grovelled information. This also elegantly avoids
;;; metacircularity issues when wrapping objects.
(defun partial-class-for-type (unwrapped-type)
  (with-locked-hash-table (*class-table*)
    (multiple-value-bind (cached-class presentp)
        #1= (gethash unwrapped-type *class-table*)
      (if presentp
          cached-class
          (setf #1# (make-instance 'python-class
                                   ;; Make sure the `initialize-instance' method
                                   ;; gets called
                                   :direct-superclasses
                                   `(,(find-class 'python-object-wrapper))
                                   :python-type nil))))))

(defun fixup-class (class type &rest args
                    &key direct-superclasses)
  (let ((needs-reinitializing (or (not (initializedp class))
                                  (not (endp args))))
        (direct-superclasses (mapcar {if (symbolp %1) (find-class %1) %1}
                                     (ensure-list direct-superclasses)))
        (args (delete-from-plist args :direct-superclasses)))
    (unless (and (initializedp class) (not needs-reinitializing))
      (let ((mutex (mutex class)))
        (with-recursive-lock-held (mutex)
          (unless (and (initializedp class) (not needs-reinitializing))
            (apply 'reinitialize-instance class
                   :python-type type
                   :mutex mutex
                   :direct-superclasses
                   (nconc direct-superclasses
                          (mapcar 'lisp-class-for-python-type
                                  (handler-case (get-bases type)
                                    (error () ())))
                          `(,(find-class 'python-object-wrapper)))
                   args)
            (setf (initializedp class) t)))))))

(defmacro with-partial-class ((class type &optional args) &body body)
  (once-only (type args)
    `(let ((,class (with-unwrapped-object (unwrapped-type ,type)
                     (partial-class-for-type unwrapped-type))))
       (prog1 (progn ,@body)
         (apply #'fixup-class ,class (wrap-pointer ,type) ,args)))))


(defmethod wrap-pointer ((pointer python-object-wrapper))
  pointer)
(defmethod wrap-pointer ((pointer system-area-pointer))
  (unless (null-pointer-p pointer)
    (or #1= (gethash pointer *wrapper-cache*)
        (with-partial-class (class (unwrapped-python-type pointer))
          (setf #1# (make-instance class :python-object pointer))))))
(defmethod wrap-pointer (pointer)
  (convert-to-python pointer))


(defun lisp-class-for-python-type (python-type &rest args)
  (with-partial-class (class python-type args)
    class))

(defmethod convert-to-python ((object system-area-pointer))
  (convert-to-python (wrap-pointer object)))


(defun ensure-python-class (name python-type &rest args)
  (let ((class (apply 'lisp-class-for-python-type python-type args)))
    (sb-kernel:with-world-lock ()
      (setf (class-name class) name)
      (setf (find-class name) class))))

(defmacro define-python-class (name python-expr &rest args)
  ;; KLUDGE: suppress warnings by telling SBCL about the class at macroexpansion
  ;; time. This avoids warnings when the class definition is combined with, say,
  ;; method definitions in something like a defbootstrap. This should probably
  ;; be done via the MOP, but whatever.
  #+sbcl (sb-kernel::preinform-compiler-about-class-type name t)
  `(ensure-python-class ',name ,python-expr ,@args))

(defmacro define-python-class-from-c (name var-name &rest args)
  (destructuring-bind (var-symbol &key deref) (ensure-list var-name)
    (let ((ptr `(foreign-symbol-pointer ,var-symbol)))
      `(define-python-class ,name ,(if deref `(mem-ref ,ptr :pointer) ptr)
         ,@args))))
