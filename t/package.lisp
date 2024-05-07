(uiop:define-package   :cl-couch-tests
  (:use       :cl :fiveam)
  (:nicknames :couch.tests)
  (:documentation "doc"))

(in-package :couch.tests)

(defun main ()
  (run-all-tests))
