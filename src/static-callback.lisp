#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/static-callback
    (:documentation "Python callbacks allocated in static space")
  (:use :cl)
  (:use :alexandria :cffi :named-readtables)
  (:use :com.andrewsoutar.bootstrap :com.andrewsoutar.brace-lambda)
  (:use :com.andrewsoutar.embedded-python/grovel)
  (:use
   :com.andrewsoutar.embedded-python/src/ffi-types
   :com.andrewsoutar.embedded-python/src/gil
   :com.andrewsoutar.embedded-python/src/init)
  (:export #:define-static-python-callback))
(in-package :com.andrewsoutar.embedded-python/src/static-callback)

(in-readtable brace-lambda)

(defmacro define-static-python-callback
    (name-and-options (self arg-or-args &optional kwargs) &body body)
  (destructuring-bind (name &rest flags) (ensure-list name-and-options)
    (let ((flags (or flags `(:varargs ,@ (when kwargs `(:keywords)))))
          (callback-name (copy-symbol name)))
      (multiple-value-bind (body declarations docstring) (parse-body body)
        `(progn
           (defcallback ,callback-name py-object
               ((,self (py-object :borrowed t))
                (,arg-or-args (py-object :borrowed t))
                ,@ (when kwargs `((,kwargs (py-object :borrowed t)))))
             ,@declarations
             (without-gil ,@body))
           (defvar ,name)
           (setf (documentation ',name 'variable) ',docstring)
           (defbootstrap ,name (:after start-python :ephemeral t)
             {()
              (let ((method-def (foreign-alloc '(:struct py-method-def))))
                (with-foreign-slots ((name method flags doc) method-def
                                     (:struct py-method-def))
                  (setf name ,(symbol-name name)
                        method (callback ,callback-name)
                        flags ',flags
                        doc ""))
                (setf ,name method-def))}))))))
