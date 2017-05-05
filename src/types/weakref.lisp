#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/types/weakref
    (:documentation "Python weak pointers")
  (:use :cl)
  (:use :named-readtables)
  (:use :com.andrewsoutar.bootstrap)
  (:use
   :com.andrewsoutar.embedded-python/src/class
   :com.andrewsoutar.embedded-python/src/ffi-types
   :com.andrewsoutar.embedded-python/src/init
   :com.andrewsoutar.embedded-python/src/syntax
   :com.andrewsoutar.embedded-python/src/types
   :com.andrewsoutar.embedded-python/src/vm-call)
  (:export #:python-weakref))
(in-package :com.andrewsoutar.embedded-python/src/types/weakref)

(in-readtable python-and-braces)

(defcfun-py (weakref-new "PyWeakref_NewRef") py-object
  (object py-object)
  (callback py-object))

(defbootstrap python-weakref (:after python-syntax)
  {()
   (define-python-class python-weakref
       (with-imports (weakref)
         [weakref.ref]))

   (defmethod construct-python-instance ((instance python-weakref) &rest args
                                         &key object callback python-args)
     (if object
         (apply #'call-next-method instance
                :python-args `(,object ,callback ,@python-args)
                args)
         (call-next-method)))})
