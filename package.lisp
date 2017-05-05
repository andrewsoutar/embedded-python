(uiop:define-package :com.andrewsoutar.embedded-python
    (:documentation "Embedded Python 3")
  (:nicknames :com.andrewsoutar.embedded-python/package)
  (:use
   :com.andrewsoutar.embedded-python/src/boot
   :com.andrewsoutar.embedded-python/src/class
   :com.andrewsoutar.embedded-python/src/types/function)
  (:use-reexport
   :com.andrewsoutar.embedded-python/src/modules
   :com.andrewsoutar.embedded-python/src/syntax)
  (:export #:boot-python #:define-python-class))
