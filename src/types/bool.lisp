#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/types/bool
    (:documentation "Python booleans")
  (:use :cl)
  (:use :named-readtables)
  (:use :com.andrewsoutar.bootstrap :com.andrewsoutar.brace-lambda)
  (:use :com.andrewsoutar.embedded-python/grovel)
  (:use
   :com.andrewsoutar.embedded-python/src/class
   :com.andrewsoutar.embedded-python/src/ffi-types
   :com.andrewsoutar.embedded-python/src/init
   :com.andrewsoutar.embedded-python/src/operators
   :com.andrewsoutar.embedded-python/src/refcount
   :com.andrewsoutar.embedded-python/src/syntax
   :com.andrewsoutar.embedded-python/src/types)
  (:export #:python-bool))
(in-package :com.andrewsoutar.embedded-python/src/types/bool)

(in-readtable brace-lambda)

(defvar *python-false*)
(defvar *python-true*)

(defbootstrap python-bool (:after (start-python python-syntax))
  {()
   (with-imports (builtins)
     (destructuring-bind (true false)
         (mapcar {non-lispy-python-dot builtins %*}
                 '("True" "False"))
       (setf *python-false* false
             *python-true* true)))

   (define-python-class python-bool (python-type (class-of *python-true*)))

   (values (defmethod convert-from-python ((object python-bool))
             ;; Bools are actually just ints
             (not (zerop (call-next-method))))

           (defmethod convert-to-python ((object (eql t)))
             *python-true*))}
  {(from-method &rest to-methods)
   (remove-method #'convert-from-python from-method)
   (mapcar {remove-method #'convert-to-python %*} to-methods)
   (values)})
