#+named-readtables
(named-readtables:in-readtable :standard)

(asdf:defsystem :com.andrewsoutar.embedded-python/grovel
  :description "cffi-grovelling for embedded-python"
  :version "0.0.0"
  :author ("Andrew Soutar <andrew@andrewsoutar.com>")
  :maintainer "Andrew Soutar <andrew@andrewsoutar.com>"
  :defsystem-depends-on (:cffi-grovel)
  :depends-on (:cffi :uiop)
  :components
  ((:module "grovel"
    :components
    ((:cffi-grovel-file "grovel" :depends-on ("package" "sysconfig"))
     (:file "package")
     (:file "sysconfig" :depends-on ("package"))))))

(asdf:defsystem :com.andrewsoutar.embedded-python
  :description "Python 3 interoperability layer for Common Lisp"
  :version "0.0.0"
  :author ("Andrew Soutar <andrew@andrewsoutar.com>")
  :maintainer "Andrew Soutar <andrew@andrewsoutar.com>"
  :defsystem-depends-on (:asdf-package-system)
  :class :package-inferred-system
  :depends-on (:uiop :com.andrewsoutar.embedded-python/package))
