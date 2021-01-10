#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/vm-call
    (:documentation "Defining calls into/out of the CPython VM")
  (:use :cl)
  (:use :alexandria :anaphora :cffi :named-readtables)
  (:import-from :uiop #:nest)
  (:use :com.andrewsoutar.brace-lambda)
  #+sbcl (:import-from :sb-vm #:floating-point-modes)
  (:use
   :com.andrewsoutar.embedded-python/src/gil)
  (:export #:defcfun-py))
(in-package :com.andrewsoutar.embedded-python/src/vm-call)

(in-readtable brace-lambda)

(defcfun (set-python-interrupt "PyErr_SetInterrupt") :void)

(defmacro defcfun-py ((name c-name) return-type &body args)
  (let ((helper-name (copy-symbol name))
        (arg-names (mapcar 'car args)))
    `(progn
       (defcfun (,helper-name ,c-name) ,return-type ,@args)
       (defun ,name (,@arg-names)
	 (let (#+sbcl (orig-modes (sb-vm:floating-point-modes)))
	   (unwind-protect
		(progn
		  #+sbcl (setf (floating-point-modes) 0)
		  (with-gil
		    (,helper-name ,@arg-names)))
	     #+sbcl (setf (floating-point-modes) orig-modes)))))))
