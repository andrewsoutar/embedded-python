#+named-readtables
(named-readtables:in-readtable :standard)

(uiop:define-package :com.andrewsoutar.embedded-python/src/types
    (:documentation "Interoperability with CLOS")
  (:use :cl)
  (:use :alexandria :bordeaux-threads :named-readtables)
  (:import-from :uiop #:nest)
  (:use :com.andrewsoutar.brace-lambda)
  #+sbcl (:use :sb-mop)
  #+sbcl (:import-from :sb-ext #:finalize)
  #+sbcl (:import-from :sb-pcl #:ensure-class-finalized)
  (:use
   :com.andrewsoutar.embedded-python/src/refcount)
  (:export #:python-class #:python-type #:mutex #:initializedp
           #:python-object-wrapper #:unwrap
           #:convert-to-python #:convert-from-python
           #:make-python-object-lambda
           #:construct-python-instance))
(in-package :com.andrewsoutar.embedded-python/src/types)

(in-readtable brace-lambda)

(defclass python-class (funcallable-standard-class)
  ((python-type :initarg :python-type
                :initform nil
                :reader python-type)
   (mutex :initarg :mutex
          :initform (make-recursive-lock)
          :reader mutex)
   (initialized :initform nil
                :accessor initializedp)))

(macrolet ((make-validator (class-type superclass-type)
             `(defmethod validate-superclass ((class ,class-type)
                                              (superclass ,superclass-type))
                (and (eq (type-of superclass) ',superclass-type)
                     (eq (type-of class) ',class-type)))))
  (make-validator python-class python-class)
  (make-validator python-class funcallable-standard-class)
  (make-validator python-class standard-class)
  (make-validator standard-class python-class)
  (make-validator funcallable-standard-class python-class))


(defclass python-object-wrapper ()
  ((python-object :initarg :python-object
                  :reader unwrap))
  (:metaclass python-class))

(defgeneric construct-python-instance (object &key &allow-other-keys)
  (:method ((object python-object-wrapper) &key python-args python-kwargs)
    (apply (python-type (class-of object))
           (append (ensure-list python-args) `(,python-kwargs)))))

(defmethod make-instance :around ((class python-class) &rest initargs
                                  &key python-object)
  (if python-object
      (call-next-method)
      (apply 'construct-python-instance
             (class-prototype (ensure-class-finalized class))
             initargs)))

(defvar *recursive* nil)
(defmethod initialize-instance :after ((instance python-object-wrapper)
                                       &key python-object)
  (set-funcallable-instance-function instance
                                     (make-python-object-lambda instance))
  (nest
   #+nil (let ((str (unless *recursive*
                      (let ((*recursive* t))
                        (format nil "~S" instance))))))
   (finalize instance {handler-case (decref python-object)
                        (error (e)
                          (format t "Error finalizing wrapper:~%~A" e)
                          (error e))})))

(defgeneric convert-to-python (object)
  (:method (object) (error "Don't know how to convert ~S to Python" object))
  (:method ((object python-object-wrapper)) object)
  (:method ((object python-class)) (python-type object)))

(defgeneric convert-from-python (object)
  (:method ((object python-object-wrapper)) object))

(define-setf-expander convert-from-python (object-form &environment env)
  (get-setf-expansion object-form env))
