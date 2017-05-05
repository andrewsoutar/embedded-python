(in-package :com.andrewsoutar.embedded-python/grovel)

(defparameter *python* "python")

(defun sysconfig (flagname)
  (run-program
   `(,*python*
     "-c"
     ,(format nil "import sysconfig; print(sysconfig.get_config_var('~A'))"
              flagname))
   :output '(:string :stripped t)))
