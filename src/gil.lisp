#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/gil
    (:documentation "Python's Global Interpreter Lock")
  (:use :cl)
  (:use :alexandria :cffi)
  (:use :com.andrewsoutar.embedded-python/grovel)
  (:use :com.andrewsoutar.embedded-python/src/macros)
  (:export #:with-gil #:without-gil #:save-thread #:restore-thread))
(in-package :com.andrewsoutar.embedded-python/src/gil)

(defcfun (acquire-gil "PyGILState_Ensure") python-gil-state)
(defcfun (release-gil "PyGILState_Release") :void (state python-gil-state))

(define-state-encapsulation (with-gil gil) ()
                            (acquire-gil)
                            (release-gil gil))


(defcfun (save-thread "PyEval_SaveThread") :pointer)
(defcfun (restore-thread "PyEval_RestoreThread") :void
  (thread-state :pointer))

(define-state-encapsulation (without-gil thread-state) ()
                            (save-thread)
                            (restore-thread thread-state))
