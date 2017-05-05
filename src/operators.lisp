#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/operators
    (:documentation "The three basic operators (dot, sub, call)")
  (:use :cl)
  (:use :alexandria :cffi :named-readtables)
  (:use :com.andrewsoutar.brace-lambda)
  (:use
   :com.andrewsoutar.embedded-python/src/ffi-types
   :com.andrewsoutar.embedded-python/src/types
   :com.andrewsoutar.embedded-python/src/vm-call)
  (:export #:python-dot #:non-lispy-python-dot
           #:python-sub #:non-lispy-python-sub
           #:python-call #:non-lispy-python-call))
(in-package :com.andrewsoutar.embedded-python/src/operators)

(in-readtable brace-lambda)

(defmacro frobnicate (name suffix-str has-setter &rest args)
  (let ((helper (format-symbol (symbol-package name) "~A-~A" 'non-lispy name))
        (setter (format-symbol nil "~A-~A" 'set name))
        (getter-str (format nil "PyObject_~A~A"
                            (if has-setter "Get" "") suffix-str))
        (setter-str (format nil "PyObject_Set~A" suffix-str))
        (parameter-names (mapcar 'car args)))
    `(progn
       (defcfun-py (,helper ,getter-str) py-object ,@args)
       (defmacro ,name ,parameter-names
         `(convert-from-python (,',helper ,,@parameter-names)))
       ,@ (when has-setter
            `((defcfun-py (,setter ,setter-str) zero-on-success
                ,@args
                (new-value py-object))
              (defun (setf ,helper) (new-value ,@parameter-names)
                (,setter ,@parameter-names new-value)))))))

(frobnicate python-dot "AttrString" t (object py-object) (property :string))
(frobnicate python-sub "Item" t (object py-object) (key py-object))

(defun make-dict (thing)
  (typecase thing
    (null (null-pointer))
    ((and list (cons cons list))
     (loop with table = (make-hash-table :test 'equal)
           for (key . value) in thing
           do (setf (gethash (string-downcase key) table) value)
           finally (return table)))
    (hash-table thing)
    (list (loop with table = (make-hash-table :test 'equal)
                for (key value) on thing by #'cddr
                do (setf (gethash key table) value)
                finally (return table)))))
(defctype py-dict-object (:wrapper py-object :to-c make-dict))
(frobnicate python-call "Call" nil
  (function py-object) (args py-object) (kwargs py-dict-object))

(defun make-python-object-lambda (instance)
  (compose
   {apply 'non-lispy-python-call instance %1}
   {let ((maybe-kwargs (car (last %%))))
     (if (and (listp maybe-kwargs)
              (evenp (length maybe-kwargs)))
         `(,(butlast %%) ,maybe-kwargs)
         `(,%% ()))}))
