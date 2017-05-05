#+named-readtables
(named-readtables:in-readtable :standard)

#-sbcl (error "You need SBCL to use SBCL-SEQUENCE")

(uiop:define-package :com.andrewsoutar.embedded-python/src/types/sbcl-sequence
    (:documentation #. (format nil "An extensible sequence type utilizing ~
Python's sequence protocol"))
  (:use :cl)
  (:use :alexandria :named-readtables)
  (:use :com.andrewsoutar.embedded-python/grovel)
  (:use :com.andrewsoutar.bootstrap :com.andrewsoutar.brace-lambda)
  (:use
   :com.andrewsoutar.embedded-python/src/class
   :com.andrewsoutar.embedded-python/src/ffi-types
   :com.andrewsoutar.embedded-python/src/init
   :com.andrewsoutar.embedded-python/src/types
   :com.andrewsoutar.embedded-python/src/utils/symbols
   :com.andrewsoutar.embedded-python/src/vm-call
   :com.andrewsoutar.embedded-python/src/types/tuple)
  (:export #:python-sequence #:populate-sequence))
(in-package :com.andrewsoutar.embedded-python/src/types/sbcl-sequence)

(in-readtable brace-lambda)

(defclass python-sequence (sequence python-object-wrapper) ()
  (:metaclass python-class))

(defcfun-py (python-sequencep "PySequence_Check") :boolean
  (object py-object))

(defgeneric populate-sequence (sequence &rest elements)
  (:method ((sequence python-sequence) &rest elements)
    (loop for element in elements
          for i from 0
          do (setf (elt sequence i) element))))

(defmethod initialize-instance :after ((object python-sequence) &key)
  (unless (python-sequencep object)
    (error "~A does not implement Python's Sequence protocol" object)))

(defmethod construct-python-instance :around ((object python-sequence)
                                              &key elements &allow-other-keys)
  (let ((list (call-next-method)))
    (apply 'populate-sequence list elements)
    list))

(defmacro frobnicate ((name c-name) return-type &body args)
  (let ((helper (symbolize nil (car (last (ensure-list name))) 'helper)))
    `(progn
       (defcfun-py (,helper ,c-name) ,return-type
         ,@ (mapcar {subseq %1 0 2} args))
       ,(let ((ordered-args
                (mapcar
                 'car
                 (stable-sort
                  (copy-list
                   `(((,(caar args) python-sequence)
                      ,@ (cdar args))
                     ,@ (cdr args)))
                  {if (and %1 %2)
                      (< %1 %2)
                      (or (minusp (or %1 0))
                          (plusp (or %2 0)))}
                  :key 'caddr))))
          `(defmethod ,name ,ordered-args
             ,(let ((helper-expr
                      `(,helper ,@ (mapcar 'car args))))
                (if (eq (car (ensure-list return-type)) 'py-object)
                    `(convert-from-python ,helper-expr)
                    helper-expr))
             ,@ (when (eq 'setf (car (ensure-list name)))
                  `(,(car ordered-args))))))))

(frobnicate (sequence:length "PySequence_Size") py-ssize (sequence py-object))
(frobnicate (sequence:elt "PySequence_GetItem") (py-object :borrowed t)
  (sequence py-object)
  (index py-ssize))
(frobnicate ((setf sequence:elt) "PySequence_SetItem") zero-on-success
  (sequence py-object)
  (index py-ssize)
  (new-value (py-object :stolen t) -1))

(defcfun-py (repeat "PySequence_Repeat") py-object
  (sequence py-object)
  (count py-ssize))
(defcfun-py (nrepeat "PySequence_InPlaceRepeat") py-object
  (sequence py-object)
  (count py-ssize))
(defcfun-py (get-slice "PySequence_GetSlice") py-object
  (sequence py-object)
  (stat py-ssize)
  (end py-ssize))
(defcfun-py (set-slice "PySequence_SetSlice") zero-on-success
  (sequence py-object)
  (start py-ssize)
  (end py-ssize)
  (new-sequence py-object))
(defcfun-py (delete-slice "PySequence_DelSlice") zero-on-success
  (sequence py-object)
  (start py-ssize)
  (end py-ssize))

(defvar *filler*)

(defbootstrap python-sequence (:after python-tuple)
  {()
   (setf *filler* (convert-to-python '(())))})

(defmethod sequence:adjust-sequence ((sequence python-sequence) length
                                     &key (initial-element nil initial-elementp)
                                       (initial-contents nil initial-contentsp))
  (when (or initial-elementp initial-contentsp)
    (set-slice sequence 0 length (if initial-elementp
                                     (nrepeat `(,initial-element) length)
                                     initial-contents)))
  (let ((current-length (length sequence)))
    (cond ((> length current-length)
           (set-slice
            sequence current-length length
            (repeat *filler*
                    (- length current-length))))
          ((< length current-length)
           (delete-slice sequence length current-length))))
  sequence)

(defmethod sequence:make-sequence-like
    ((sequence python-sequence) length
     &key (initial-element nil initial-elementp)
       (initial-contents nil initial-contentsp))
  (if initial-elementp
      (nrepeat
       (make-instance (class-of sequence) :elements `(,initial-element))
       length)
      (make-instance (class-of sequence)
                     :elements (if initial-contentsp
                                   (coerce initial-contents 'list)
                                   (make-list length)))))

(macrolet ((frob (name c-name)
             (let ((helper (symbolize nil name 'helper)))
               `(progn
                  (defcfun-py (,helper ,c-name) py-ssize
                    (sequence py-object)
                    (item py-object))
                  (defmethod ,name (item (sequence python-sequence)
                                    &key from-end (start 0 startp)
                                      (end (length sequence) endp)
                                      test test-not key)
                    (if (and (not from-end) (not test-not) (not key)
                             (member test `(python-equalp #+nil ,#'python-equalp)))
                        (let ((result (,helper
                                       (if (or startp endp)
                                           (get-slice sequence start end)
                                           sequence)
                                       item)))
                          (if (= result -1)
                              (error "Call failed")
                              result))
                        (call-next-method)))))))
  (frob sequence:count "PySequence_Count")
  (frob sequence:position "PySequence_Index"))

(defmethod sequence:subseq ((sequence python-sequence)
                            start &optional (end (length sequence)))
  (get-slice sequence start end))

(defcfun-py (delete-item "PySequence_DelItem") :int
  (sequence py-object)
  (index py-ssize))
(macrolet ((define-deleter (name method first-arg)
             `(defmethod ,name (,first-arg (sequence python-sequence)
                                &rest args
                                &key from-end
                                  (start (if from-end (length sequence) 0))
                                  count
                                &allow-other-keys)
                (let ((args (delete-from-plist args :start :count)))
                  (loop for i from 0
                        until (when count (= i count))
                        for subseq-start = start then (if from-end
                                                          (1- subseq-end)
                                                          (1+ subseq-end))
                        for subseq-end = (apply #',method ,first-arg sequence
                                                :start subseq-start
                                                args)
                        while subseq-end
                        do (delete-item sequence subseq-end)
                        finally (return sequence))))))
  (define-deleter sequence:delete position item)
  (define-deleter sequence:delete-if position-if predicate)
  (define-deleter sequence:delete-if-not position-if-not predicate))
