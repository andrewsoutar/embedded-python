#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/types/int
    (:documentation "Python integers (with arbitrary precision support!)")
  (:use :cl)
  (:use :cffi :named-readtables)
  (:use :com.andrewsoutar.bootstrap :com.andrewsoutar.brace-lambda)
  (:use :com.andrewsoutar.embedded-python/grovel)
  (:use
   :com.andrewsoutar.embedded-python/src/class
   :com.andrewsoutar.embedded-python/src/ffi-types
   :com.andrewsoutar.embedded-python/src/init
   :com.andrewsoutar.embedded-python/src/types
   :com.andrewsoutar.embedded-python/src/vm-call)
  (:export #:python-int))
(in-package :com.andrewsoutar.embedded-python/src/types/int)

(in-readtable brace-lambda)

(defcfun-py (python-logior "PyNumber_Or") py-object
  (num1 py-object)
  (num2 py-object))
(defcfun-py (python-logand "PyNumber_And") py-object
  (num1 py-object)
  (num2 py-object))
(defcfun-py (python-ashl "PyNumber_Lshift") py-object
  (int py-object)
  (count py-object))
(defcfun-py (python-ashr "PyNumber_Rshift") py-object
  (int py-object)
  (count py-object))

(defcfun-py (%make-int "PyLong_FromLongLong") py-object
  (int py-long-long))
(defcfun-py (%make-uint "PyLong_FromUnsignedLongLong") py-object
  (uint py-unsigned-long-long))

(defcfun-py (%%convert-int-overflow "PyLong_AsLongLongAndOverflow") py-long-long
  (int py-object)
  (overflow (:pointer :int)))
(defun %convert-int-overflow (int)
  (with-foreign-object (overflow :int)
    (values (%%convert-int-overflow int overflow)
            (mem-ref overflow :int))))


(defvar *long-bits* (* (foreign-type-size 'py-long-long) 8))

(defcfun-py (%convert-int-mask "PyLong_AsUnsignedLongLongMask")
    py-unsigned-long-long
  (int py-object))

(defbootstrap python-int (:after start-python)
  {()
   (define-python-class-from-c python-int "PyLong_Type")

   (defmethod convert-to-python ((object integer))
     (loop
       for shifted-int = object then (ash shifted-int (- *long-bits*))
       for shift-count from 0 by *long-bits*
       for length from (integer-length object) downto *long-bits* by *long-bits*
       for python-piece = (%make-uint (ldb (byte *long-bits* 0) shifted-int))
       for python-int = python-piece
         then (python-logior python-int (python-ashl python-piece shift-count))
       finally (return
                 (let ((signed-end (%make-int shifted-int)))
                   (if (zerop shift-count)
                       signed-end
                       (python-logior python-int
                                      (python-ashl signed-end shift-count)))))))

   (defmethod convert-from-python ((object python-int))
     (loop with accumulator = 0
           for shifted-int = object then (python-ashr shifted-int *long-bits*)
           for shift-count from 0 by *long-bits*
           do (multiple-value-bind (result overflow)
                  (%convert-int-overflow shifted-int)
                (if (zerop overflow)
                    (return (logior accumulator (ash result shift-count)))
                    (setf (ldb (byte *long-bits* shift-count) accumulator)
                          (%convert-int-mask shifted-int))))))})
