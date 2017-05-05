#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/macros
    (:documentation "Helper macros")
  (:use :cl)
  (:use :alexandria)
  #+sbcl
  (:import-from :sb-sys #:without-interrupts #:allow-with-interrupts
                #:with-local-interrupts #:with-interrupts)
  (:export #:threadsafe-unwind-protect #:with-interrupts
           #:define-state-encapsulation))
(in-package :com.andrewsoutar.embedded-python/src/macros)

#-sbcl
(defmacro with-interrupts (&body body)
  `(progn ,@body))

(defmacro threadsafe-unwind-protect ((var val) protected &body cleanup)
  #. (format nil "Bind `var' to the value returned by `val' in such a way that ~
neither the binding process nor the cleanup process can be interrupted in any ~
way, even by another thread.")
  #+sbcl
  `(without-interrupts
     (let ((,var (allow-with-interrupts ,val)))
       (unwind-protect
            (with-local-interrupts ,protected)
         (allow-with-interrupts
           (progn ,@cleanup)))))
  #-sbcl
  `(unwind-protect
        (let ((,var ,val))
          ,protected)
     ,@cleanup))

(defmacro define-state-encapsulation ((name state) lambda-list
                                      initializer finalizer)
  (with-gensyms (body)
    `(defmacro ,name (,@lambda-list &body ,body)
       (with-gensyms (state)
         `(threadsafe-unwind-protect
              (,state ,',initializer)
              (progn ,@,body)
            (let ((,',state ,state))
              ,',finalizer))))))
