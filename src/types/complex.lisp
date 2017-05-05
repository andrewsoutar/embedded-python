#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/types/complex
    (:documentation "Python complex numbers")
  (:use :cl)
  (:use :named-readtables)
  (:use :com.andrewsoutar.bootstrap :com.andrewsoutar.brace-lambda)
  (:use
   :com.andrewsoutar.embedded-python/src/class
   :com.andrewsoutar.embedded-python/src/ffi-types
   :com.andrewsoutar.embedded-python/src/init
   :com.andrewsoutar.embedded-python/src/types
   :com.andrewsoutar.embedded-python/src/vm-call)
  (:export #:python-complex))
(in-package :com.andrewsoutar.embedded-python/src/types/complex)

(in-readtable brace-lambda)

(defcfun-py (make-python-complex "PyComplex_FromDoubles") py-object
  (real :double)
  (imag :double))

(defcfun-py (python-complex-real "PyComplex_RealAsDouble") :double
  (object py-object))
(defcfun-py (python-complex-imag "PyComplex_ImagAsDouble") :double
  (object py-object))

(defbootstrap python-complex (:after start-python)
  {()
   (define-python-class-from-c python-complex "PyComplex_Type")

   (defmethod convert-to-python ((object complex))
     (make-python-complex (realpart object) (imagpart object)))

   (defmethod convert-from-python ((object python-complex))
     (complex (python-complex-real object) (python-complex-imag object)))})
