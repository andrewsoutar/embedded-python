#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/init
    (:documentation "Starting up python")
  (:use :cl)
  (:use :cffi :named-readtables :uiop)
  (:use :com.andrewsoutar.bootstrap :com.andrewsoutar.brace-lambda)
  (:use :com.andrewsoutar.embedded-python/grovel)
  (:use
   :com.andrewsoutar.embedded-python/src/gil
   :com.andrewsoutar.embedded-python/src/macros)
  (:export #:start-python))
(in-package :com.andrewsoutar.embedded-python/src/init)

(in-readtable brace-lambda)

(define-foreign-library libpython3
  (t (:default "libpython3")))
(use-foreign-library libpython3)

(defcfun (init "Py_InitializeEx") :void
  (initialize-signals :boolean))

(defcfun (fini "Py_Finalize") :void)

(defcfun (init-threads "PyEval_InitThreads") :void)

(defcfun (set-argv "PySys_SetArgvEx") :void
  (argc :int)
  (argv (:pointer :pointer))
  (update-path :boolean))

(defcfun (decode-locale "Py_DecodeLocale") :pointer
  (arg :string)
  (size size))

(defvar *python-main-thread* nil)

(defbootstrap start-python (:after libpython :ephemeral t)
  {()
   (init nil)
   (init-threads)
   (with-foreign-object (argv :pointer 2)
     (setf (mem-aref argv :pointer 0) (decode-locale "" 0))
     (setf (mem-aref argv :pointer 1) (null-pointer))
     (set-argv 1 argv nil))
   (save-thread)}
  {(thread-state)
   (restore-thread thread-state)
   (fini)
   (values)})
