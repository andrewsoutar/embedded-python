(in-package :com.andrewsoutar.embedded-python/grovel)

(cc-flags #. (format nil "-I~A" (sysconfig "INCLUDEPY")))

#. (if (not (string= "1" (sysconfig "Py_DEBUG")))
       '(define "Py_LIMITED_API")
       (values))

(include "Python.h")

(ctype size "size_t")
(ctype py-ssize "Py_ssize_t")
(ctype py-long-long "PY_LONG_LONG")
(ctype py-unsigned-long-long "unsigned PY_LONG_LONG")

(cstruct %py-object "PyObject")

(bitfield method-flags
          ((:varargs "METH_VARARGS"))
          ((:keywords "METH_KEYWORDS"))
          ((:no-args "METH_NOARGS"))
          ((:one-arg "METH_O"))
          ((:class "METH_CLASS"))
          ((:static "METH_STATIC"))
          ((:coexist "METH_COEXIST")))

(cstruct py-method-def "PyMethodDef"
         (name "ml_name" :type :string)
         (method "ml_meth" :type :pointer)
         (flags "ml_flags" :type method-flags)
         (doc "ml_doc" :type :string))

(ctype python-gil-state "PyGILState_STATE")

(constantenum py-compare-op
              ((:lt "Py_LT"))
              ((:le "Py_LE"))
              ((:eq "Py_EQ"))
              ((:ne "Py_NE"))
              ((:gt "Py_GT"))
              ((:ge "Py_GE")))
