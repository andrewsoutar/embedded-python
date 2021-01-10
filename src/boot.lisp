#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/boot
    (:documentation "Machinery for bootstrapping Python")
  (:use :cl)
  (:use :com.andrewsoutar.bootstrap)
  (:use
   :com.andrewsoutar.embedded-python/src/types/bool
   :com.andrewsoutar.embedded-python/src/types/complex
   :com.andrewsoutar.embedded-python/src/types/dict
   :com.andrewsoutar.embedded-python/src/types/exception
   :com.andrewsoutar.embedded-python/src/types/float
   :com.andrewsoutar.embedded-python/src/types/function
   :com.andrewsoutar.embedded-python/src/types/int
   :com.andrewsoutar.embedded-python/src/types/list
   :com.andrewsoutar.embedded-python/src/types/none
   :com.andrewsoutar.embedded-python/src/types/object
   :com.andrewsoutar.embedded-python/src/types/str
   :com.andrewsoutar.embedded-python/src/types/tuple
   :com.andrewsoutar.embedded-python/src/types/weakref)
  (:export #:boot-python))
(in-package :com.andrewsoutar.embedded-python/src/boot)

(defbootstrap boot-python (:after (python-bool
                                   python-complex
                                   python-dict
                                   python-base-exception
                                   python-float
                                   python-function
                                   python-int
                                   python-list
                                   python-none
                                   python-sequence
                                   python-str
                                   python-tuple
                                   python-weakref)))
