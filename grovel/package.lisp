(uiop:define-package :com.andrewsoutar.embedded-python/grovel
    (:documentation "Symbols grovelled from Python")
  (:use :cl :uiop)
  (:export #:sysconfig
           #:size #:py-ssize #:py-long-long #:py-unsigned-long-long
           #:%py-object
           #:py-method-def #:name #:method #:flags #:doc
           #:method-flags
           #:python-gil-state #:py-compare-op))
