#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/syntax
    (:documentation "Syntax for using Python")
  (:use :cl)
  (:use :alexandria :named-readtables)
  (:use :com.andrewsoutar.bootstrap :com.andrewsoutar.brace-lambda)
  #+sbcl (:import-from :sb-unicode #:whitespace-p)
  (:use
   :com.andrewsoutar.embedded-python/src/init
   :com.andrewsoutar.embedded-python/src/modules
   :com.andrewsoutar.embedded-python/src/operators
   :com.andrewsoutar.embedded-python/src/types
   :com.andrewsoutar.embedded-python/src/types/str)
  (:export #:with-imports #:python-syntax #:python-and-braces #:with-builtins))
(in-package :com.andrewsoutar.embedded-python/src/syntax)

(in-readtable brace-lambda)

(defmacro with-macro-character ((char new-function &optional non-terminating-p)
                                &body body)
  (with-gensyms (old-function old-non-terminating-p)
    (once-only (char new-function non-terminating-p)
      `(multiple-value-bind (,old-function ,old-non-terminating-p)
           (get-macro-character ,char)
         (unwind-protect
              (progn
                (set-macro-character ,char ,new-function ,non-terminating-p)
                ,@body)
           (set-macro-character ,char ,old-function
                                (or (not ,old-function)
                                    ,old-non-terminating-p)))))))

(defmacro with-macro-characters (bindings &body body)
  (if (endp bindings)
      `(progn ,@body)
      `(with-macro-character ,(car bindings)
         (with-macro-characters ,(cdr bindings) ,@body))))

(defun read-expression (stream)
  (labels ((next-char () (read-char stream t nil t))
           (next-pyexpr () (read-expression stream))
           (unread (char) (unread-char char stream) char)
           (next-real-char () (loop for char = (next-char)
                                    until (not (whitespace-p char))
                                    finally (return char)))
           (read-identifier ()
             (coerce 
              (loop for char = (next-real-char) then (next-char)
                    while (or (alphanumericp char)
                              (char= #\_ char))
                    collect char
                    finally (unread char))
              'string)))
    (let ((expression
            (let ((readtable (copy-readtable *readtable*)))
              (loop for char across ".,[]()" do
                (set-macro-character char (or (get-macro-character char *readtable*) (constantly nil)) nil readtable))
              (let ((*readtable* readtable))
                (read stream t nil t)))))
      (loop
        (multiple-value-bind (operator args)
            (let ((char (next-real-char)))
              (case char
                ((#\.) (values :dot `(,(read-identifier))))
                ((#\[) (values :sub (prog1 `(,(next-pyexpr))
                                      (assert (char= #\] (next-real-char))))))
                ((#\() (values :call
                               (if (let ((char (next-real-char)))
                                     (unless (char= #\) char)
                                       (unread char)))
                                   (loop for expression = (next-pyexpr)
                                         for char = (next-real-char)
                                         if (member char '(#\, #\))
                                                    :test 'char=)
                                           collect expression into args
                                         else
                                           nconc
                                           (prog2 (unread char)
                                               `(,expression ,(next-pyexpr))
                                             (setf char (next-real-char)))
                                           into kwargs
                                         until (char= #\) char)
                                         finally
                                            (return `(`(,,@args) `(,,@kwargs))))
                                   '(() ()))))
                (t (unread char) (return expression))))
          (setf expression `(,(format-symbol #.*package* "~A-~A"
                                             'non-lispy-python operator)
                             ,expression ,@args)))))))

(defun read-left-bracket (stream char)
  (declare (ignore char))
  (prog1 `(convert-from-python ,(read-expression stream))
    (assert (endp (read-delimited-list #\] stream t)))))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (handler-bind ((style-warning #'muffle-warning))      ; Muffle warnings from redefinitions
    (defreadtable python-syntax
      (:merge :standard)
      (:macro-char #\[ 'read-left-bracket)
      (:macro-char #\] {error "Unmatched close bracket found."}))
    (defreadtable python-and-braces
      (:merge :standard)
      (:merge brace-lambda)
      (:merge python-syntax))))

(defmacro with-builtins ((&rest builtins) &body body)
  (with-gensyms (builtins-module)
    `(with-imports ((,builtins-module "builtins"))
       (let ,(mapcar (compose
                       {((name &optional (builtin (string-downcase name))))
                        `(,name (python-dot ,builtins-module ,builtin))}
                       'ensure-list)
              builtins)
         ,@body))))

(macrolet ((define-fun-for-op (operation () &body body)
             `(defmethod slot-missing ((class python-class) (instance python-object-wrapper)
                                       slot-name (operation (eql ',operation))
                                       &optional new-value)
                (declare (ignorable new-value))
                ,@body))
           (property-string ()
             `(string-downcase (symbol-name slot-name)))
           (dot ()
             `(python-dot instance (property-string))))
  (define-fun-for-op slot-value ()
    (dot))
  (define-fun-for-op setf ()
    (setf (dot) new-value))
  (define-fun-for-op slot-boundp ()
    (with-builtins (hasattr)
      (funcall hasattr instance (property-string))))
  (define-fun-for-op slot-makunbound ()
    (with-builtins (delattr)
      (funcall delattr instance (property-string)))))

(defbootstrap python-syntax (:after (start-python python-str)))
